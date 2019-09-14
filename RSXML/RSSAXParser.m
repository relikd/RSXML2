//
//  MIT License (MIT)
//
//  Copyright (c) 2016 Brent Simmons
//  Copyright (c) 2018 Oleg Geier
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//  of the Software, and to permit persons to whom the Software is furnished to do
//  so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import <libxml/tree.h>
#import <libxml/xmlstring.h>
#import <libxml/parser.h>
#import "RSSAXParser.h"

const NSErrorDomain kLIBXMLParserErrorDomain = @"LIBXMLParserErrorDomain";


@interface RSSAXParser ()
@property (nonatomic, weak) id<RSSAXParserDelegate> delegate;
@property (nonatomic, assign) xmlParserCtxtPtr context;
@property (nonatomic, assign) BOOL storingCharacters;
@property (nonatomic) NSMutableData *characters;
@property (nonatomic, assign) BOOL isHTMLParser;
@property (nonatomic, assign) BOOL delegateRespondsToInternedStringMethod;
@property (nonatomic, assign) BOOL delegateRespondsToInternedStringForValueMethod;
@property (nonatomic, assign) BOOL delegateRespondsToStartElementMethod;
@property (nonatomic, assign) BOOL delegateRespondsToEndElementMethod;
@property (nonatomic, assign) BOOL delegateRespondsToCharactersFoundMethod;
@property (nonatomic, assign) BOOL delegateRespondsToEndOfDocumentMethod;
@end


@implementation RSSAXParser

+ (void)initialize {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		xmlInitParser();
	});
}

#pragma mark - Init

- (instancetype)initWithDelegate:(id<RSSAXParserDelegate>)delegate {

	self = [super init];
	if (self == nil)
		return nil;

	_delegate = delegate;
	_delegateRespondsToCharactersFoundMethod = [_delegate respondsToSelector:@selector(saxParser:XMLCharactersFound:length:)];
	_delegateRespondsToEndOfDocumentMethod = [_delegate respondsToSelector:@selector(saxParserDidReachEndOfDocument:)];
	_delegateRespondsToInternedStringMethod = [_delegate respondsToSelector:@selector(saxParser:internedStringForName:prefix:)];
	_delegateRespondsToInternedStringForValueMethod = [_delegate respondsToSelector:@selector(saxParser:internedStringForValue:length:)];
	
	if ([[_delegate class] respondsToSelector:@selector(isHTMLParser)] && [[_delegate class] isHTMLParser]) {
		_isHTMLParser = YES;
		_delegateRespondsToStartElementMethod = [_delegate respondsToSelector:@selector(saxParser:XMLStartElement:attributes:)];
		_delegateRespondsToEndElementMethod = [_delegate respondsToSelector:@selector(saxParser:XMLEndElement:)];
	} else {
		_delegateRespondsToStartElementMethod = [_delegate respondsToSelector:@selector(saxParser:XMLStartElement:prefix:uri:numberOfNamespaces:namespaces:numberOfAttributes:numberDefaulted:attributes:)];
		_delegateRespondsToEndElementMethod = [_delegate respondsToSelector:@selector(saxParser:XMLEndElement:prefix:uri:)];
	}

	return self;
}

- (void)dealloc {
	if (_context != nil) {
		xmlFreeParserCtxt(_context);
		_context = nil;
	}
	_delegate = nil;
}


#pragma mark - API


static xmlSAXHandler saxHandlerStruct;

// docref in header
- (void)parseBytes:(const void *)bytes numberOfBytes:(NSUInteger)numberOfBytes {

	_parsingError = nil;

	if (self.context == nil) {
		if (self.isHTMLParser) {
			xmlCharEncoding characterEncoding = xmlDetectCharEncoding(bytes, (int)numberOfBytes);
			self.context = htmlCreatePushParserCtxt(&saxHandlerStruct, (__bridge void *)self, nil, 0, nil, characterEncoding);
			htmlCtxtUseOptions(self.context, XML_PARSE_RECOVER | XML_PARSE_NONET | HTML_PARSE_COMPACT);
		} else {
			self.context = xmlCreatePushParserCtxt(&saxHandlerStruct, (__bridge void *)self, nil, 0, nil);
			xmlCtxtUseOptions(self.context, XML_PARSE_RECOVER | XML_PARSE_NOENT);
		}
	}

	@autoreleasepool {
		if (self.isHTMLParser) {
			htmlParseChunk(self.context, (const char *)bytes, (int)numberOfBytes, 0);
		} else {
			xmlParseChunk(self.context, (const char *)bytes, (int)numberOfBytes, 0);
		}
	}
	
	[self finishParsing];
}

/**
 Call after @c parseData: or @c parseBytes:numberOfBytes:
 */
- (void)finishParsing {

	NSAssert(self.context != nil, nil);
	if (self.context == nil)
		return;

	@autoreleasepool {
		if (self.isHTMLParser) {
			htmlParseChunk(self.context, nil, 0, 1);
			htmlFreeParserCtxt(self.context);
		} else {
			xmlParseChunk(self.context, nil, 0, 1);
			xmlFreeParserCtxt(self.context);
		}
		self.context = nil;
		self.characters = nil;
	}
}

// docref in header
- (void)cancel {
	@autoreleasepool {
		xmlStopParser(self.context);
	}
}

// docref in header
- (void)beginStoringCharacters {
	self.storingCharacters = YES;
	self.characters = [NSMutableData new];
}

/// Will be called after each closing tag and the document end.
- (void)endStoringCharacters {
	self.storingCharacters = NO;
	self.characters = nil;
}

/// @return @c nil if not storing characters. UTF-8 encoded.
- (NSData *)currentCharacters {
	if (!self.storingCharacters) {
		return nil;
	}
	return self.characters;
}

/// Convenience method to get string version of @c currentCharacters.
- (NSString *)currentString {
	NSData *d = self.currentCharacters;
	if (!d || d.length == 0) {
		return nil;
	}
	return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
}

/// Trim whitespace and newline characters from @c currentString.
- (NSString *)currentStringWithTrimmedWhitespace {
	return [self.currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}


#pragma mark - Attributes Dictionary


// docref in header
- (NSDictionary *)attributesDictionary:(const xmlChar **)attributes numberOfAttributes:(NSInteger)numberOfAttributes {

	if (numberOfAttributes < 1 || !attributes) {
		return nil;
	}

	NSMutableDictionary *d = [NSMutableDictionary new];

	@autoreleasepool {
		for (NSInteger i = 0, j = 0; i < numberOfAttributes; i++, j+=5) {

			NSUInteger lenValue = (NSUInteger)(attributes[j + 4] - attributes[j + 3]);
			NSString *value = nil;

			if (self.delegateRespondsToInternedStringForValueMethod) {
				value = [self.delegate saxParser:self internedStringForValue:(const void *)attributes[j + 3] length:lenValue];
			}
			if (!value) {
				value = [[NSString alloc] initWithBytes:(const void *)attributes[j + 3] length:lenValue encoding:NSUTF8StringEncoding];
			}

			NSString *attributeName = nil;

			if (self.delegateRespondsToInternedStringMethod) {
				attributeName = [self.delegate saxParser:self internedStringForName:(const xmlChar *)attributes[j] prefix:(const xmlChar *)attributes[j + 1]];
			}

			if (!attributeName) {
				attributeName = [NSString stringWithUTF8String:(const char *)attributes[j]];
				if (attributes[j + 1]) {
					NSString *attributePrefix = [NSString stringWithUTF8String:(const char *)attributes[j + 1]];
					attributeName = [NSString stringWithFormat:@"%@:%@", attributePrefix, attributeName];
				}
			}

			if (value && attributeName) {
				d[attributeName] = value;
			}
		}
	}
	return d;
}

// docref in header
- (NSDictionary *)attributesDictionaryHTML:(const xmlChar **)attributes {
	
	if (!attributes) {
		return nil;
	}
	
	NSMutableDictionary *d = [NSMutableDictionary new];
	NSInteger ix = 0;
	NSString *currentKey = nil;
	while (true) {
		
		const xmlChar *oneAttribute = attributes[ix];
		ix++;
		
		if (!currentKey && !oneAttribute) {
			break;
		}
		if (!currentKey) {
			currentKey = [NSString stringWithUTF8String:(const char *)oneAttribute];
		}
		else {
			NSString *value = nil;
			if (oneAttribute) {
				value = [NSString stringWithUTF8String:(const char *)oneAttribute];
			}
			d[currentKey] = (value ? value : @"");
			currentKey = nil;
		}
	}
	return d;
}


#pragma mark - Callbacks


- (void)xmlEndDocument {

	@autoreleasepool {
		if (self.delegateRespondsToEndOfDocumentMethod) {
			[self.delegate saxParserDidReachEndOfDocument:self];
		}

		[self endStoringCharacters];
	}
}


- (void)xmlCharactersFound:(const xmlChar *)ch length:(NSUInteger)length {

	@autoreleasepool {
		if (self.storingCharacters) {
			[self.characters appendBytes:(const void *)ch length:length];
		}

		if (self.delegateRespondsToCharactersFoundMethod) {
			[self.delegate saxParser:self XMLCharactersFound:ch length:length];
		}
	}
}


- (void)xmlStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(int)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(int)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {

	if (self.delegateRespondsToStartElementMethod) {
		@autoreleasepool {
			[self.delegate saxParser:self XMLStartElement:localName prefix:prefix uri:uri numberOfNamespaces:numberOfNamespaces namespaces:namespaces numberOfAttributes:numberOfAttributes numberDefaulted:numberDefaulted attributes:attributes];
		}
	}
}


- (void)xmlStartHTMLElement:(const xmlChar *)localName attributes:(const xmlChar **)attributes {

	if (self.delegateRespondsToStartElementMethod) {
		@autoreleasepool {
			[self.delegate saxParser:self XMLStartElement:localName attributes:attributes];
		}
	}
}


- (void)xmlEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {

	@autoreleasepool {
		if (self.delegateRespondsToEndElementMethod) {
			[self.delegate saxParser:self XMLEndElement:localName prefix:prefix uri:uri];
		}
		[self endStoringCharacters];
	}
}


- (void)xmlEndHTMLElement:(const xmlChar *)localName {

	@autoreleasepool {
		if (self.delegateRespondsToEndElementMethod) {
			[self.delegate saxParser:self XMLEndElement:localName];
		}
		[self endStoringCharacters];
	}
}

- (void)xmlParsingErrorOccured:(NSError*)error {
	if (!self.parsingError) // grep first encountered error
		_parsingError = error;
}

@end


static void startElementSAX(void *context, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes) {
	[(__bridge RSSAXParser *)context xmlStartElement:localname prefix:prefix uri:URI numberOfNamespaces:nb_namespaces namespaces:namespaces numberOfAttributes:nb_attributes numberDefaulted:nb_defaulted attributes:attributes];
}

static void	endElementSAX(void *context, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI) {
	[(__bridge RSSAXParser *)context xmlEndElement:localname prefix:prefix uri:URI];
}

static void	charactersFoundSAX(void *context, const xmlChar *ch, int len) {
	[(__bridge RSSAXParser *)context xmlCharactersFound:ch length:(NSUInteger)len];
}

static void endDocumentSAX(void *context) {
	[(__bridge RSSAXParser *)context xmlEndDocument];
}

static void startElementSAX_HTML(void *context, const xmlChar *localname, const xmlChar **attributes) {
	[(__bridge RSSAXParser *)context xmlStartHTMLElement:localname attributes:attributes];
}

static void	endElementSAX_HTML(void *context, const xmlChar *localname) {
	[(__bridge RSSAXParser *)context xmlEndHTMLElement:localname];
}

static void errorOccuredSAX(void *context, const char *format, ...) {
	xmlErrorPtr err = xmlGetLastError();
	if (err && err->level == XML_ERR_FATAL) {
		int errCode = err->code;
		char * msg = err->message;
		NSString *errMsg = [[NSString stringWithFormat:@"%s", msg] stringByTrimmingCharactersInSet:
							[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		NSError *error = [NSError errorWithDomain:kLIBXMLParserErrorDomain code:errCode
										 userInfo:@{ NSLocalizedDescriptionKey: errMsg }];
		[(__bridge RSSAXParser *)context xmlParsingErrorOccured:error];
	}
	xmlResetLastError();
}


static xmlSAXHandler saxHandlerStruct = {
	nil,					/* internalSubset */
	nil,					/* isStandalone   */
	nil,					/* hasInternalSubset */
	nil,					/* hasExternalSubset */
	nil,					/* resolveEntity */
	nil,					/* getEntity */
	nil,					/* entityDecl */
	nil,					/* notationDecl */
	nil,					/* attributeDecl */
	nil,					/* elementDecl */
	nil,					/* unparsedEntityDecl */
	nil,					/* setDocumentLocator */
	nil,					/* startDocument */
	endDocumentSAX,			/* endDocument */
	startElementSAX_HTML,	/* startElement*/
	endElementSAX_HTML,		/* endElement */
	nil,					/* reference */
	charactersFoundSAX,		/* characters */
	nil,					/* ignorableWhitespace */
	nil,					/* processingInstruction */
	nil,					/* comment */
	nil,					/* warning */
	errorOccuredSAX,		/* error */
	nil,					/* fatalError //: unused error() get all the errors */
	nil,					/* getParameterEntity */
	nil,					/* cdataBlock */
	nil,					/* externalSubset */
	XML_SAX2_MAGIC,
	nil,
	startElementSAX,		/* startElementNs */
	endElementSAX,			/* endElementNs */
	nil						/* serror */
};
