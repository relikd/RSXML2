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

#import <libxml/xmlstring.h>

#import "RSOPMLParser.h"
#import "RSOPMLItem.h"

@interface RSOPMLParser()
@property (nonatomic, assign) BOOL parsingHead;
@property (nonatomic) RSOPMLItem *opmlDocument;
@property (nonatomic) NSMutableArray<RSOPMLItem*> *itemStack;
@end


@implementation RSOPMLParser

#pragma mark - RSXMLParserDelegate

+ (BOOL)isOPMLParser { return YES; }

+ (NSArray<const NSString*>*)parserRequireOrderedTags {
	return @[@"<opml", @"<outline"];
}

- (BOOL)xmlParserWillStartParsing {
	self.opmlDocument = [RSOPMLItem new];
	self.itemStack = [NSMutableArray arrayWithObject:self.opmlDocument];
	return YES;
}

- (id)xmlParserWillReturnDocument {
	return self.opmlDocument;
}


#pragma mark - RSSAXParserDelegate


- (void)saxParser:(RSSAXParser *)SAXParser XMLStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(NSInteger)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(NSInteger)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {

	int len = xmlStrlen(localName);

	if (len == 7 && EqualBytes(localName, "outline", 7)) {
		RSOPMLItem *item = [RSOPMLItem new];
		item.attributes = [SAXParser attributesDictionary:attributes numberOfAttributes:numberOfAttributes];
		
		[self.itemStack.lastObject addChild:item];
		[self.itemStack addObject:item];
	}
	else if (len == 4 && EqualBytes(localName, "head", 4)) {
		self.parsingHead = YES;
	}
	else if (self.parsingHead) {
		[SAXParser beginStoringCharacters];
	}
}


- (void)saxParser:(RSSAXParser *)SAXParser XMLEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {

	int len = xmlStrlen(localName);

	if (len == 7 && EqualBytes(localName, "outline", 7)) {
		[self.itemStack removeLastObject]; // safe to be called on empty array
	}
	else if (len == 4 && EqualBytes(localName, "head", 4)) {
		self.parsingHead = NO;
	}
	else if (self.parsingHead) { // handle xml tags in head as if they were attributes
		NSString *key = [NSString stringWithFormat:@"%s", localName];
		[self.itemStack.lastObject setAttribute:SAXParser.currentStringWithTrimmedWhitespace forKey:key];
	}
}


- (NSString *)saxParser:(RSSAXParser *)SAXParser internedStringForName:(const xmlChar *)name prefix:(const xmlChar *)prefix {

	if (prefix) {
		return nil;
	}

	int len = xmlStrlen(name);
	switch (len) {
		case 4:
			if (EqualBytes(name, "text", 4)) return OPMLTextKey;
			if (EqualBytes(name, "type", 4)) return OPMLTypeKey;
			break;
		case 5:
			if (EqualBytes(name, "title", 5)) return OPMLTitleKey;
			break;
		case 6:
			if (EqualBytes(name, "xmlUrl", 6)) return OPMLXMLURLKey;
			break;
		case 7:
			if (EqualBytes(name, "version", 7)) return OPMLVersionKey;
			if (EqualBytes(name, "htmlUrl", 7)) return OPMLHMTLURLKey;
			break;
		case 11:
			if (EqualBytes(name, "description", 11)) return OPMLDescriptionKey;
			break;
	}
	return nil;
}


- (NSString *)saxParser:(RSSAXParser *)SAXParser internedStringForValue:(const void *)bytes length:(NSUInteger)length {

	if (length < 1) {
		return @"";
	} else if (length == 3) {
		if (EqualBytes(bytes, "RSS", 3)) return @"RSS";
		if (EqualBytes(bytes, "rss", 3)) return @"rss";
	}
	return nil;
}

@end
