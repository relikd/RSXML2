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

#import "RSHTMLMetadataParser.h"
#import "RSHTMLMetadata.h"
#import "NSString+RSXML.h"
#import "NSDictionary+RSXML.h"

@interface RSHTMLMetadataParser()
@property (nonatomic, readonly) NSURL *baseURL;
@property (nonatomic) NSString *faviconLink;
@property (nonatomic) NSMutableArray<RSHTMLMetadataIconLink*> *iconLinks;
@property (nonatomic) NSMutableArray<RSHTMLMetadataFeedLink*> *feedLinks;
@end

@implementation RSHTMLMetadataParser

#pragma mark - RSXMLParserDelegate

+ (BOOL)isHTMLParser { return YES; }

- (BOOL)xmlParserWillStartParsing {
	_baseURL = [NSURL URLWithString:self.documentURI];
	_iconLinks = [NSMutableArray new];
	_feedLinks = [NSMutableArray new];
	return YES;
}

- (id)xmlParserWillReturnDocument {
	RSHTMLMetadata *metadata = [[RSHTMLMetadata alloc] init];
	metadata.faviconLink = self.faviconLink;
	metadata.feedLinks = [self.feedLinks copy];
	metadata.iconLinks = [self.iconLinks copy];
	return metadata;
}


#pragma mark - RSSAXParserDelegate


- (void)saxParser:(RSSAXParser *)SAXParser XMLStartElement:(const xmlChar *)localName attributes:(const xmlChar **)attributes {

	if (xmlStrlen(localName) != 4) {
		return;
	}
	else if (EqualBytes(localName, "body", 4)) {
		[SAXParser cancel]; // we're only interested in head
	}
	else if (EqualBytes(localName, "link", 4)) {
		[self parseLinkItemWithAttributes:[SAXParser attributesDictionaryHTML:attributes]];
	}
}

- (void)parseLinkItemWithAttributes:(NSDictionary*)attribs {
	if (!attribs || attribs.count == 0)
		return;
	NSString *rel = [attribs rsxml_objectForCaseInsensitiveKey:@"rel"];
	if (!rel || rel.length == 0)
		return;
	NSString *link = [attribs rsxml_objectForCaseInsensitiveKey:@"href"];
	if (!link) {
		link = [attribs rsxml_objectForCaseInsensitiveKey:@"src"];
		if (!link)
			return;
	}
	
	rel = [rel lowercaseString];
	
	if ([rel isEqualToString:@"shortcut icon"]) {
		self.faviconLink = [link absoluteURLWithBase:self.baseURL];
	}
	else if ([rel isEqualToString:@"icon"] || [rel hasPrefix:@"apple-touch-icon"]) { // also matching "apple-touch-icon-precomposed"
		RSHTMLMetadataIconLink *icon = [RSHTMLMetadataIconLink new];
		icon.link = [link absoluteURLWithBase:self.baseURL];
		icon.title = rel;
		icon.sizes = [attribs rsxml_objectForCaseInsensitiveKey:@"sizes"];
		[self.iconLinks addObject:icon];
	}
	else if ([rel isEqualToString:@"alternate"]) {
		RSFeedType type = RSFeedTypeFromLinkTypeAttribute([attribs rsxml_objectForCaseInsensitiveKey:@"type"]);
		if (type != RSFeedTypeNone) {
			RSHTMLMetadataFeedLink *feedLink = [RSHTMLMetadataFeedLink new];
			feedLink.link = [link absoluteURLWithBase:self.baseURL];
			feedLink.title = [attribs rsxml_objectForCaseInsensitiveKey:@"title"];
			feedLink.type = type;
			[self.feedLinks addObject:feedLink];
		}
	}
}

@end
