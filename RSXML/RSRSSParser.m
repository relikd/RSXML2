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

#import "RSRSSParser.h"
#import "RSParsedFeed.h"
#import "RSParsedArticle.h"
#import "NSString+RSXML.h"
#import "NSDictionary+RSXML.h"

static NSString *kRDFAboutKey = @"rdf:about";

@interface RSRSSParser () <RSSAXParserDelegate>
@property (nonatomic) BOOL parsingArticle;
@property (nonatomic) BOOL parsingChannelImage;
@property (nonatomic) BOOL guidIsPermalink;
@property (nonatomic) BOOL endRSSFound;
@property (nonatomic) NSURL *baseURL;
@end

// TODO: handle RSS 1.0
@implementation RSRSSParser

#pragma mark - RSXMLParserDelegate

+ (NSArray<const NSString *> *)parserRequireOrderedTags {
	return @[@"<rss", @"<channel>"];
}

#pragma mark - RSSAXParserDelegate

- (void)saxParser:(RSSAXParser *)SAXParser XMLStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(NSInteger)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(NSInteger)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {

	if (self.endRSSFound) {
		return;
	}

	int len = xmlStrlen(localName);

	if (prefix != NULL) {
		if (!self.parsingArticle || self.parsingChannelImage) {
			return;
		}
		if (len != 4 && len != 7) {
			return;
		}
		int prefLen = xmlStrlen(prefix);
		if (prefLen == 2 && EqualBytes(prefix, "dc", 2)) {
			if (EqualBytes(localName, "date", 4) || EqualBytes(localName, "creator", 7)) {
				[SAXParser beginStoringCharacters];
			}
		}
		else if (len == 7 && prefLen == 7 && EqualBytes(prefix, "content", 7) && EqualBytes(localName, "encoded", 7)) {
			[SAXParser beginStoringCharacters];
		}
		return;
	}
	// else: localname without prefix
	switch (len) {
		case 4:
			if (EqualBytes(localName, "item", 4)) {
				self.parsingArticle = YES;
				self.currentArticle = [self.parsedFeed appendNewArticle];
				
				NSDictionary *attribs = [SAXParser attributesDictionary:attributes numberOfAttributes:numberOfAttributes];
				if (attribs) {
					NSString *about = attribs[kRDFAboutKey]; // RSS 1.0 guid
					if (about) {
						self.currentArticle.guid = about;
						self.currentArticle.permalink = about;
					}
				}
			}
			else if (EqualBytes(localName, "guid", 4)) {
				NSDictionary *attribs = [SAXParser attributesDictionary:attributes numberOfAttributes:numberOfAttributes];
				NSString *isPermaLinkValue = [attribs rsxml_objectForCaseInsensitiveKey:@"isPermaLink"];
				if (!isPermaLinkValue || ![isPermaLinkValue isEqualToString:@"false"]) {
					self.guidIsPermalink = YES;
				} else {
					self.guidIsPermalink = NO;
				}
			}
			break;
		case 5:
			if (EqualBytes(localName, "image", 5)) {
				self.parsingChannelImage = YES;
			}
			break;
	}

	if (self.parsingArticle || !self.parsingChannelImage) {
		[SAXParser beginStoringCharacters];
	}
}


- (void)saxParser:(RSSAXParser *)SAXParser XMLEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {

	if (self.endRSSFound) {
		return;
	}
	
	int len = xmlStrlen(localName);

	// Meta parsing
	     if (len == 3 && EqualBytes(localName, "rss", 3))   { self.endRSSFound = YES; }
	else if (len == 4 && EqualBytes(localName, "item", 4))  { self.parsingArticle = NO; }
	else if (len == 5 && EqualBytes(localName, "image", 5)) { self.parsingChannelImage = NO; }
	// Always exit if prefix is set
	else if (prefix != NULL)
	{
		if (!self.parsingArticle) {
			// Feed parsing
			return;
		}
		int prefLen = xmlStrlen(prefix);
		// Article parsing
		switch (len) {
			case 4:
				if (prefLen == 2 && EqualBytes(prefix, "dc", 2) && EqualBytes(localName, "date", 4))
					self.currentArticle.datePublished = [self dateFromCharacters:SAXParser.currentCharacters];
				return;
			case 7:
				if (prefLen == 2 && EqualBytes(prefix, "dc", 2) && EqualBytes(localName, "creator", 7)) {
					self.currentArticle.author = SAXParser.currentStringWithTrimmedWhitespace;
				}
				else if (prefLen == 7 && EqualBytes(prefix, "content", 7) && EqualBytes(localName, "encoded", 7)) {
					self.currentArticle.body = [self decodeHTMLEntities:SAXParser.currentStringWithTrimmedWhitespace];
				}
				return;
		}
	}
	// Article parsing
	else if (self.parsingArticle)
	{
		switch (len) {
			case 4:
				if (EqualBytes(localName, "link", 4)) {
					self.currentArticle.link = [SAXParser.currentStringWithTrimmedWhitespace absoluteURLWithBase:self.baseURL];
				}
				else if (EqualBytes(localName, "guid", 4)) {
					self.currentArticle.guid = SAXParser.currentStringWithTrimmedWhitespace;
					if (self.guidIsPermalink) {
						self.currentArticle.permalink = [self.currentArticle.guid absoluteURLWithBase:self.baseURL];
					}
				}
				return;
			case 5:
				if (EqualBytes(localName, "title", 5))
					self.currentArticle.title = [self decodeHTMLEntities:SAXParser.currentStringWithTrimmedWhitespace];
				return;
			case 6:
				if (EqualBytes(localName, "author", 6))
					self.currentArticle.author = SAXParser.currentStringWithTrimmedWhitespace;
				return;
			case 7:
				if (EqualBytes(localName, "pubDate", 7))
					self.currentArticle.datePublished = [self dateFromCharacters:SAXParser.currentCharacters];
				return;
			case 11:
				if (EqualBytes(localName, "description", 11))
					self.currentArticle.abstract = [self decodeHTMLEntities:SAXParser.currentStringWithTrimmedWhitespace];
				return;
		}
	}
	// Feed parsing
	else if (!self.parsingChannelImage)
	{
		switch (len) {
			case 4:
				if (EqualBytes(localName, "link", 4)) {
					self.parsedFeed.link = [SAXParser.currentStringWithTrimmedWhitespace absoluteURLWithBase:nil];
					self.baseURL = [NSURL URLWithString:self.parsedFeed.link];
				}
				return;
			case 5:
				if (EqualBytes(localName, "title", 5))
					self.parsedFeed.title = SAXParser.currentStringWithTrimmedWhitespace;
				return;
			case 11:
				if (EqualBytes(localName, "description", 11))
					self.parsedFeed.subtitle = SAXParser.currentStringWithTrimmedWhitespace;
				return;
		}
	}
}


- (NSString *)saxParser:(RSSAXParser *)SAXParser internedStringForName:(const xmlChar *)name prefix:(const xmlChar *)prefix {

	int len = xmlStrlen(name);

	if (prefix) {
		if (len == 5 && EqualBytes(prefix, "rdf", 4) && EqualBytes(name, "about", 5)) { // 4 because prefix length is not checked
			return kRDFAboutKey;
		}
		return nil;
	}

	switch (len) {
		case 3:
			if (EqualBytes(name, "url", 3)) { return @"url"; }
			break;
		case 4:
			if (EqualBytes(name, "type", 4)) { return @"type"; }
			break;
		case 6:
			if (EqualBytes(name, "length", 6)) { return @"length"; }
			break;
		case 11:
			if (EqualBytes(name, "isPermaLink", 11)) { return @"isPermaLink"; }
			break;
	}
	return nil;
}


- (NSString *)saxParser:(RSSAXParser *)SAXParser internedStringForValue:(const void *)bytes length:(NSUInteger)length {

	switch (length) {
		case 4:
			if (EqualBytes(bytes, "true", 4)) { return @"true"; }
			break;
		case 5:
			if (EqualBytes(bytes, "false", 5)) { return @"false"; }
			break;
	}
	return nil;
}


@end
