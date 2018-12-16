//
//  RSOPMLParser.m
//  RSXML
//
//  Created by Brent Simmons on 7/12/15.
//  Copyright © 2015 Ranchero Software, LLC. All rights reserved.
//

#import "RSOPMLParser.h"
#import <libxml/xmlstring.h>
#import "RSXMLData.h"
#import "RSSAXParser.h"
#import "RSOPMLItem.h"
#import "RSXMLError.h"


void RSParseOPML(RSXMLData *xmlData, RSParsedOPMLBlock callback) {

	NSCParameterAssert(xmlData);
	NSCParameterAssert(callback);

	dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{

		@autoreleasepool {

			RSOPMLParser *parser = [[RSOPMLParser alloc] initWithXMLData:xmlData];

			RSOPMLItem *document = parser.opmlDocument;
			NSError *error = parser.error;

			dispatch_async(dispatch_get_main_queue(), ^{

				callback(document, error);
			});
		}
	});
}


@interface RSOPMLParser () <RSSAXParserDelegate>

@property (nonatomic, readwrite) RSOPMLItem *opmlDocument;
@property (nonatomic, readwrite) NSError *error;
@property (nonatomic) NSMutableArray<RSOPMLItem*> *itemStack;

@end


@implementation RSOPMLParser


#pragma mark - Init

- (instancetype)initWithXMLData:(RSXMLData *)XMLData {

	self = [super init];
	if (!self) {
		return nil;
	}

	[self parse:XMLData];

	return self;
}


#pragma mark - Private

- (void)parse:(RSXMLData *)XMLData {

	@autoreleasepool {

		if ([self canParseData:XMLData.data]) {
			RSSAXParser *parser = [[RSSAXParser alloc] initWithDelegate:self];
			
			self.itemStack = [NSMutableArray new];
			self.opmlDocument = [RSOPMLItem new];
			[self.itemStack addObject:self.opmlDocument];
			
			[parser parseData:XMLData.data];
			[parser finishParsing];
			
		} else {
			
			NSString *filename = nil;
			NSURL *url = [NSURL URLWithString:XMLData.urlString];
			if (url && url.isFileURL) {
				filename = url.path.lastPathComponent;
			}
			if (!filename) {
				filename = XMLData.urlString;
			}
			self.error = RSXMLMakeError(RSXMLErrorFileNotOPML, filename);
		}
	}
}

- (BOOL)canParseData:(NSData *)d {

	// Check for <opml and <outline near the top.

	@autoreleasepool {

		NSString *s = [[NSString alloc] initWithBytesNoCopy:(void *)d.bytes length:d.length encoding:NSUTF8StringEncoding freeWhenDone:NO];
		if (!s) {
			NSDictionary *options = @{NSStringEncodingDetectionSuggestedEncodingsKey : @[@(NSUTF8StringEncoding)]};
			(void)[NSString stringEncodingForData:d encodingOptions:options convertedString:&s usedLossyConversion:nil];
		}
		if (!s) {
			return NO;
		}

		static const NSInteger numberOfCharactersToSearch = 4096;
		NSRange rangeToSearch = NSMakeRange(0, numberOfCharactersToSearch);
		if (s.length < numberOfCharactersToSearch) {
			rangeToSearch.length = s.length;
		}

		NSRange opmlRange = [s rangeOfString:@"<opml" options:NSCaseInsensitiveSearch range:rangeToSearch];
		if (opmlRange.location == NSNotFound) {
			return NO;
		}

		NSRange outlineRange = [s rangeOfString:@"<outline" options:NSLiteralSearch range:rangeToSearch];
		if (outlineRange.location == NSNotFound) {
			return NO;
		}

		if (outlineRange.location < opmlRange.location) {
			return NO;
		}
	}

	return YES;
}


- (void)popItem {

	NSAssert(self.itemStack.count > 0, nil);

	/*If itemStack is empty, bad things are happening.
	 But we still shouldn't crash in production.*/

	if (self.itemStack.count > 0) {
		[self.itemStack removeLastObject];
	}
}


#pragma mark - RSSAXParserDelegate

static const char *kOutline = "outline";
static const char kOutlineLength = 8;
static const char *kHead = "head";
static const char kHeadLength = 5;
static BOOL isHead = NO;

- (void)saxParser:(RSSAXParser *)SAXParser XMLStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(NSInteger)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(NSInteger)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {

	if (RSSAXEqualTags(localName, kOutline, kOutlineLength)) {
		RSOPMLItem *item = [RSOPMLItem new];
		item.attributes = [SAXParser attributesDictionary:attributes numberOfAttributes:numberOfAttributes];
		
		[self.itemStack.lastObject addChild:item];
		[self.itemStack addObject:item];
	} else if (RSSAXEqualTags(localName, kHead, kHeadLength)) {
		isHead = YES;
	} else if (isHead) {
		[SAXParser beginStoringCharacters];
	}
}


- (void)saxParser:(RSSAXParser *)SAXParser XMLEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {

	if (RSSAXEqualTags(localName, kOutline, kOutlineLength)) {
		[self popItem];
	} else if (RSSAXEqualTags(localName, kHead, kHeadLength)) {
		isHead = NO;
	} else if (isHead) {
		NSString *key = [NSString stringWithFormat:@"%s", localName];
		[self.itemStack.lastObject setAttribute:[SAXParser currentString] forKey:key];
	}
}


- (NSString *)saxParser:(RSSAXParser *)SAXParser internedStringForName:(const xmlChar *)name prefix:(const xmlChar *)prefix {

	if (prefix) {
		return nil;
	}

	size_t nameLength = strlen((const char *)name);
	switch (nameLength) {
		case 4:
			if (RSSAXEqualTags(name, "text", 5)) return OPMLTextKey;
			if (RSSAXEqualTags(name, "type", 5)) return OPMLTypeKey;
			break;
		case 5:
			if (RSSAXEqualTags(name, "title", 6)) return OPMLTitleKey;
			break;
		case 6:
			if (RSSAXEqualTags(name, "xmlUrl", 7)) return OPMLXMLURLKey;
			break;
		case 7:
			if (RSSAXEqualTags(name, "version", 8)) return OPMLVersionKey;
			if (RSSAXEqualTags(name, "htmlUrl", 8)) return OPMLHMTLURLKey;
			break;
		case 11:
			if (RSSAXEqualTags(name, "description", 12)) return OPMLDescriptionKey;
			break;
	}
	return nil;
}


- (NSString *)saxParser:(RSSAXParser *)SAXParser internedStringForValue:(const void *)bytes length:(NSUInteger)length {

	if (length < 1) {
		return @"";
	} else if (length == 3) {
		if (RSSAXEqualBytes(bytes, "RSS", 3)) return @"RSS";
		if (RSSAXEqualBytes(bytes, "rss", 3)) return @"rss";
	}
	return nil;
}


@end
