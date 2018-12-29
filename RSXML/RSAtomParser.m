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

#import "RSAtomParser.h"
#import "RSParsedFeed.h"
#import "RSParsedArticle.h"

static NSString *kAlternateValue = @"alternate";
static NSString *kRelatedValue = @"related";

@interface RSAtomParser () <RSSAXParserDelegate>
@property (nonatomic, assign) BOOL endFeedFound;
@property (nonatomic, assign) BOOL parsingXHTML;
@property (nonatomic, assign) BOOL parsingSource;
@property (nonatomic, assign) BOOL parsingArticle;
@property (nonatomic, assign) BOOL parsingAuthor;
@property (nonatomic) NSMutableString *xhtmlString;
@end


@implementation RSAtomParser

#pragma mark - RSXMLParserDelegate

+ (NSArray<const NSString *> *)parserRequireOrderedTags {
	return @[@"<feed", @"<entry"];
}

#pragma mark - Helper

- (void)setFeedOrArticleLink:(NSDictionary*)attribs {

	NSString *urlString = attribs[@"href"];
	if (urlString.length == 0) {
		return;
	}

	NSString *rel = attribs[@"rel"];
	if (rel.length == 0) {
		rel = kAlternateValue;
	}

	if (!self.parsingArticle) { // Feed
		if (!self.parsedFeed.link && rel == kAlternateValue) {
			self.parsedFeed.link = urlString;
		}
	}
	else if (!self.parsingSource) { // Article
		if (!self.currentArticle.link && rel == kAlternateValue) {
			self.currentArticle.link = urlString;
		}
		else if (!self.currentArticle.permalink && rel == kRelatedValue) {
			self.currentArticle.permalink = urlString;
		}
	}
}


#pragma mark - Parse XHTML


- (void)addXHTMLTag:(const xmlChar *)localName attributes:(NSDictionary*)attribs {

	if (!localName) {
		return;
	}

	[self.xhtmlString appendFormat:@"<%s", localName];

	for (NSString *key in attribs) {
		NSString *val = [attribs[key] stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
		[self.xhtmlString appendFormat:@" %@=\"%@\"", key, val];
	}

	[self.xhtmlString appendString:@">"];
}

- (void)parseXHTMLEndElement:(const xmlChar *)localName length:(int)len {
	if (len == 7) {
		if (EqualBytes(localName, "content", 7)) {
			if (self.parsingArticle) {
				self.currentArticle.body = [self.xhtmlString copy];
			}
			self.parsingXHTML = NO;
		}
		else if (EqualBytes(localName, "summary", 7)) {
			if (self.parsingArticle) {
				self.currentArticle.abstract = [self.xhtmlString copy];
			}
			self.parsingXHTML = NO;
		}
	}
	[self.xhtmlString appendFormat:@"</%s>", localName];
}


#pragma mark - RSSAXParserDelegate


- (void)saxParser:(RSSAXParser *)SAXParser XMLStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(NSInteger)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(NSInteger)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {

	if (self.endFeedFound) {
		return;
	}

	if (self.parsingXHTML) {
		NSDictionary *attribs = [SAXParser attributesDictionary:attributes numberOfAttributes:numberOfAttributes];
		[self addXHTMLTag:localName attributes:attribs];
		return;
	}
	
	int len = xmlStrlen(localName);
	switch (len) {
		case 4:
			if (EqualBytes(localName, "link", 4)) {
				NSDictionary *attribs = [SAXParser attributesDictionary:attributes numberOfAttributes:numberOfAttributes];
				[self setFeedOrArticleLink:attribs];
				return;
			}
			break;
		case 5:
			if (EqualBytes(localName, "entry", 5)) {
				self.parsingArticle = YES;
				self.currentArticle = [self.parsedFeed appendNewArticle];
				return;
			}
			break;
		case 6:
			if (EqualBytes(localName, "author", 6)) {
				self.parsingAuthor = YES;
				return;
			} else if (EqualBytes(localName, "source", 6)) {
				self.parsingSource = YES;
				return;
			}
			break;
		case 7: // uses attrib
			if (self.parsingArticle) {
				break;
			}
			if (!EqualBytes(localName, "content", 7) && !EqualBytes(localName, "summary", 7)) {
				break;
			}
			NSDictionary *attribs = [SAXParser attributesDictionary:attributes numberOfAttributes:numberOfAttributes];
			if ([attribs[@"type"] isEqualToString:@"xhtml"]) {
				self.parsingXHTML = YES;
				self.xhtmlString = [NSMutableString stringWithString:@""];
				return;
			}
			break;
	}

	[SAXParser beginStoringCharacters];
}


- (void)saxParser:(RSSAXParser *)SAXParser XMLEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {

	if (self.endFeedFound) {
		return;
	}

	int len = xmlStrlen(localName);
	
	if (len == 4 && EqualBytes(localName, "feed", 4)) {
		self.endFeedFound = YES;
		return;
	}

	if (self.parsingXHTML) {
		[self parseXHTMLEndElement:localName length:len];
		return;
	}

	BOOL isArticle = (self.parsingArticle && !self.parsingSource && !prefix);

	switch (len) {
		case 2:
			if (isArticle && EqualBytes(localName, "id", 2)) {
				self.currentArticle.guid = SAXParser.currentStringWithTrimmedWhitespace;
			}
			return;
		case 5:
			if (EqualBytes(localName, "entry", 5)) {
				self.parsingArticle = NO;
			}
			else if (isArticle && EqualBytes(localName, "title", 5)) {
				self.currentArticle.title = [self decodeHTMLEntities:SAXParser.currentStringWithTrimmedWhitespace];
			}
			else if (!self.parsingArticle && !self.parsingSource && self.parsedFeed.title.length == 0) {
				if (EqualBytes(localName, "title", 5)) {
					self.parsedFeed.title = SAXParser.currentStringWithTrimmedWhitespace;
				}
			}
			return;
		case 6:
			if (EqualBytes(localName, "author", 6)) {
				self.parsingAuthor = NO;
			}
			else if (EqualBytes(localName, "source", 6)) {
				self.parsingSource = NO;
			}
			return;
		case 8:
			if (!self.parsingArticle && !self.parsingSource && self.parsedFeed.subtitle.length == 0) {
				if (EqualBytes(localName, "subtitle", 8)) {
					self.parsedFeed.subtitle = SAXParser.currentStringWithTrimmedWhitespace;
				}
			}
			return;
		case 7:
			if (isArticle) {
				if (EqualBytes(localName, "content", 7)) {
					self.currentArticle.body = [self decodeHTMLEntities:SAXParser.currentStringWithTrimmedWhitespace];
				}
				else if (EqualBytes(localName, "summary", 7)) {
					self.currentArticle.abstract = [self decodeHTMLEntities:SAXParser.currentStringWithTrimmedWhitespace];
				}
				else if (EqualBytes(localName, "updated", 7)) {
					self.currentArticle.dateModified = [self dateFromCharacters:SAXParser.currentCharacters];
				}
			}
			return;
		case 9:
			if (isArticle && EqualBytes(localName, "published", 9)) {
				self.currentArticle.datePublished = [self dateFromCharacters:SAXParser.currentCharacters];
			}
			return;
	}
}


- (void)saxParser:(RSSAXParser *)SAXParser XMLCharactersFound:(const unsigned char *)characters length:(NSUInteger)length {

	if (self.parsingXHTML) {
		[self.xhtmlString appendString:[[NSString alloc] initWithBytesNoCopy:(void *)characters length:length encoding:NSUTF8StringEncoding freeWhenDone:NO]];
	}
}


- (NSString *)saxParser:(RSSAXParser *)SAXParser internedStringForName:(const xmlChar *)name prefix:(const xmlChar *)prefix {

	int len = xmlStrlen(name);
	
	if (prefix) {
		if (len == 4 && EqualBytes(prefix, "xml", 3)) { // len == 4 is for the next two lines already
			if (EqualBytes(name, "base", 4)) { return @"xml:base"; }
			if (EqualBytes(name, "lang", 4)) { return @"xml:lang"; }
		}
		return nil;
	}

	switch (len) {
		case 3:
			if (EqualBytes(name, "rel", 3)) { return @"rel"; }
			break;
		case 4:
			if (EqualBytes(name, "type", 4)) { return @"type"; }
			if (EqualBytes(name, "href", 4)) { return @"href"; }
			break;
		case 9:
			if (EqualBytes(name, "alternate", 9)) { return kAlternateValue; }
			break;
	}

	return nil;
}


- (NSString *)saxParser:(RSSAXParser *)SAXParser internedStringForValue:(const void *)bytes length:(NSUInteger)length {

	switch (length) {
		case 2:
			if (EqualBytes(bytes, "en", 2)) { return @"en"; }
			break;
		case 4:
			if (EqualBytes(bytes, "html", 4)) { return @"html"; }
			if (EqualBytes(bytes, "text", 4)) { return @"text"; }
			if (EqualBytes(bytes, "self", 4)) { return @"self"; }
			break;
		case 7:
			if (EqualBytes(bytes, "related", 7)) { return kRelatedValue; }
			break;
		case 8:
			if (EqualBytes(bytes, "shorturl", 8)) { return @"shorturl"; }
			break;
		case 9:
			if (EqualBytes(bytes, "alternate", 9)) { return kAlternateValue; }
			if (EqualBytes(bytes, "text/html", 9)) { return @"text/html"; }
			break;
	}

	return nil;
}

@end
