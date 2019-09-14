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

#import "RSHTMLMetadata.h"

RSFeedType RSFeedTypeFromLinkTypeAttribute(NSString * typeStr) {
	if (typeStr || typeStr.length > 0) {
		typeStr = [typeStr lowercaseString];
		if ([typeStr hasSuffix:@"/rss+xml"]) {
			return RSFeedTypeRSS;
		} else if ([typeStr hasSuffix:@"/atom+xml"]) {
			return RSFeedTypeAtom;
		}
	}
	return RSFeedTypeNone;
}


@implementation RSHTMLMetadataLink
- (NSString*)description { return self.link; }
@end


@implementation RSHTMLMetadataIconLink

// docref in header
- (CGSize)getSize {
	if (self.sizes && self.sizes.length > 0) {
		NSArray<NSString*> *parts = [self.sizes componentsSeparatedByString:@"x"];
		if (parts.count == 2) {
			return CGSizeMake([parts.firstObject intValue], [parts.lastObject intValue]);
		}
	}
	return CGSizeZero;
}

- (NSString*)description {
	return [NSString stringWithFormat:@"%@ [%@] (%@)", self.title, self.sizes, self.link];
}

@end


@implementation RSHTMLMetadataFeedLink

- (NSString*)description {
	NSString *prefix;
	switch (_type) {
		case RSFeedTypeNone: prefix = @"None"; break;
		case RSFeedTypeRSS:  prefix = @"RSS"; break;
		case RSFeedTypeAtom: prefix = @"Atom"; break;
	}
	return [NSString stringWithFormat:@"[%@] %@ (%@)", prefix, self.title, self.link];
}

@end


@implementation RSHTMLMetadataAnchor

- (NSString*)description {
	if (!_tooltip) {
		return [NSString stringWithFormat:@"%@ (%@)", self.title, self.link];
	}
	return [NSString stringWithFormat:@"%@ [%@] (%@)", self.title, self.tooltip, self.link];
}

@end


@implementation RSHTMLMetadata

- (NSString*)description {
	return [NSString stringWithFormat:@"favicon: %@\nFeed links: %@\nIcons: %@\n",
			self.faviconLink, self.feedLinks, self.iconLinks];
}

@end
