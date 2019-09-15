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

@import Foundation;
@import CoreGraphics;

typedef enum {
	RSFeedTypeNone,
	RSFeedTypeRSS,
	RSFeedTypeAtom
} RSFeedType;

RSFeedType RSFeedTypeFromLinkTypeAttribute(NSString * typeStr);


@class RSHTMLMetadataIconLink, RSHTMLMetadataFeedLink;

/// Parsed result type for HTML metadata.
@interface RSHTMLMetadata : NSObject
@property (nonatomic, copy, nullable) NSString *faviconLink;
@property (nonatomic, nonnull) NSArray <RSHTMLMetadataIconLink *> *iconLinks;
@property (nonatomic, nonnull) NSArray <RSHTMLMetadataFeedLink *> *feedLinks;
@end


@interface RSHTMLMetadataLink : NSObject
@property (nonatomic, copy, nonnull) NSString *link; // absolute
@property (nonatomic, copy, nullable) NSString *title;
@end


@interface RSHTMLMetadataIconLink : RSHTMLMetadataLink
@property (nonatomic, copy, nullable) NSString *sizes;
/// Parses size on the fly. Expects the following format: @c "{int}x{int}" . Returns @c CGSizeZero otherwise.
- (CGSize)getSize;
@end


@interface RSHTMLMetadataFeedLink : RSHTMLMetadataLink // title: 'icon' or 'apple-touch-icon*'
@property (nonatomic, assign) RSFeedType type;
@end


@interface RSHTMLMetadataAnchor : RSHTMLMetadataLink // title: anchor text-value
@property (nonatomic, copy, nullable) NSString *tooltip;
@end
