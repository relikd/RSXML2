//
//  MIT License (MIT)
//
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

#import "RSXMLParser.h"
#import "RSXMLData.h"
#import "RSXMLError.h"

@interface RSXMLParser()
@property (nonatomic) RSSAXParser *parser;
@property (nonatomic) NSData *xmlData;
@property (nonatomic, copy) NSError *xmlInputError;
@end


@implementation RSXMLParser

+ (BOOL)isFeedParser { return NO; } // override
+ (BOOL)isOPMLParser { return NO; } // override
+ (BOOL)isHTMLParser { return NO; } // override
- (id)xmlParserWillReturnDocument { return nil; } // override

// docref in header
+ (instancetype)parserWithXMLData:(nonnull RSXMLData *)xmlData {
	if ([xmlData.parserClass isSubclassOfClass:[super class]]) {
		return [[xmlData.parserClass alloc] initWithXMLData:xmlData];
	}
	return [[super alloc] initWithXMLData:xmlData];
}

/**
 Internal initializer. Use the class initializer to automatically initialize to proper subclass.
 Keeps an internal pointer to the @c RSXMLData and initializes a new @c RSSAXParser.
 */
- (instancetype)initWithXMLData:(nonnull RSXMLData *)xmlData {
	self = [super init];
	if (self) {
		_documentURI = [xmlData.url copy];
		_xmlInputError = [xmlData.parserError copy];
		[self checkIfParserMatches:xmlData.parserClass];
		_xmlData = xmlData.data;
		if (!_xmlData) {
			_xmlInputError = RSXMLMakeError(RSXMLErrorNoData, _documentURI);
		}
		_parser = [[RSSAXParser alloc] initWithDelegate:self];
	}
	return self;
}

/**
 XML allows only specific lower ascii characters (<0x20), namely 0x9, 0xA, and 0xD.
 See: https://www.w3.org/TR/xml/#charsets
 */
- (void)replaceLowerAsciiBytesWithSpace {
	[_xmlData enumerateByteRangesUsingBlock:^(const void * bytes, NSRange byteRange, BOOL * stop) {
		NSUInteger max = byteRange.location + byteRange.length;
		for (NSUInteger i = byteRange.location; i < max; i++) {
			unsigned char c = ((unsigned char*)bytes)[i];
			if (c < 0x20 && c != 0x9 && c != 0xA && c != 0xD) {
				((unsigned char*)bytes)[i] = ' '; // replace lower ascii with blank
			}
		}
	}];
}

// docref in header
- (id _Nullable)parseSync:(NSError **)error {
	if (_xmlInputError) {
		if (error) *error = _xmlInputError;
		return nil;
	}
	if (_dontStopOnLowerAsciiBytes) {
		[self replaceLowerAsciiBytesWithSpace];
	}
	if ([self respondsToSelector:@selector(xmlParserWillStartParsing)] && ![self xmlParserWillStartParsing])
		return nil;

	@autoreleasepool {
		[_parser parseBytes:_xmlData.bytes numberOfBytes:_xmlData.length];
	}
	if (error) *error = _parser.parsingError;
	return [self xmlParserWillReturnDocument];
}

// docref in header
- (void)parseAsync:(void(^)(id parsedDocument, NSError *error))block {
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{ // QOS_CLASS_DEFAULT
		@autoreleasepool {
			NSError *error;
			id obj = [self parseSync:&error];
			dispatch_async(dispatch_get_main_queue(), ^{
				block(obj, error);
			});
		}
	});
}

// docref in header
- (BOOL)canParse {
	return (self.xmlInputError == nil);
}


#pragma mark - Check Parser Type Matches


/**
 @return Returns either @c ExpectingFeed, @c ExpectingOPML, @c ExpectingHTML.
 @return @c RSXMLErrorNoData for an unexpected class (e.g., if @c RSXMLParser is used directly).
 */
- (RSXMLError)getExpectedErrorForClass:(Class<RSXMLParserDelegate>)cls {
	if ([cls isFeedParser])
		return RSXMLErrorExpectingFeed;
	if ([cls isOPMLParser])
		return RSXMLErrorExpectingOPML;
	if ([cls isHTMLParser])
		return RSXMLErrorExpectingHTML;
	return RSXMLErrorNoData; // will result in 'Unknown format'
}

/**
 Check whether parsing class matches the expected parsing class. If not set @c .xmlInputError along the way.
 
 @return @c YES if @c parserClass matches, @c NO otherwise. If @c NO is returned, @c parserError is set also.
 */
- (BOOL)checkIfParserMatches:(Class<RSXMLParserDelegate>)xmlParserClass {
	if (!xmlParserClass)
		return NO;
	if (xmlParserClass != [self class]) { // && !_xmlInputError
		RSXMLError current = [self getExpectedErrorForClass:xmlParserClass];
		RSXMLError expected = [self getExpectedErrorForClass:[self class]];
		if (current != expected) {
			_xmlInputError =  RSXMLMakeErrorWrongParser(expected, current, _documentURI);
			return NO;
		}
	}
	return YES; // only if no error was set (not now, nor before)
}

@end
