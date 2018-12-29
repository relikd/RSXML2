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

#import "RSHTMLLinkParser.h"
#import "RSHTMLMetadata.h"
#import "NSDictionary+RSXML.h"

@interface RSHTMLLinkParser()
@property (nonatomic, readonly) NSURL *baseURL;
@property (nonatomic) NSMutableArray<RSHTMLMetadataAnchor*> *mutableLinksList;
@property (nonatomic) NSMutableString *currentText;
@end

@implementation RSHTMLLinkParser

#pragma mark - RSXMLParserDelegate

+ (BOOL)isHTMLParser { return YES; }

- (BOOL)xmlParserWillStartParsing {
	_baseURL = [NSURL URLWithString:self.documentURI];
	_mutableLinksList = [NSMutableArray new];
	return YES;
}

- (id)xmlParserWillReturnDocument {
	return [_mutableLinksList copy];
}


#pragma mark - RSSAXParserDelegate


- (void)saxParser:(RSSAXParser *)SAXParser XMLStartElement:(const xmlChar *)localName attributes:(const xmlChar **)attributes {

	if (EqualBytes(localName, "a", 2)) { // 2 because length is not checked
		NSDictionary *attribs = [SAXParser attributesDictionaryHTML:attributes];
		if (!attribs || attribs.count == 0) {
			return;
		}
		NSString *href = [attribs rsxml_objectForCaseInsensitiveKey:@"href"];
		if (!href) {
			return;
		}
		RSHTMLMetadataAnchor *obj = [RSHTMLMetadataAnchor new];
		[self.mutableLinksList addObject:obj];
		// set link properties
		obj.tooltip = [attribs rsxml_objectForCaseInsensitiveKey:@"title"];
		obj.link = [[NSURL URLWithString:href relativeToURL:self.baseURL] absoluteString];
		// begin storing data for link description
		[SAXParser beginStoringCharacters];
		self.currentText = [NSMutableString new];
	}
}

- (void)saxParser:(RSSAXParser *)SAXParser XMLEndElement:(const xmlChar *)localName {

	if (self.currentText != nil) {
		NSString *str = SAXParser.currentStringWithTrimmedWhitespace;
		if (str) {
			[self.currentText appendString:str];
		}
		if (EqualBytes(localName, "a", 2)) { // 2 because length is not checked
			self.mutableLinksList.lastObject.title = self.currentText;
			self.currentText = nil;
		}
	}
}

@end
