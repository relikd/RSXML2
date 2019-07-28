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

#import "RSParsedArticle.h"
#import "NSString+RSXML.h"

@interface RSParsedArticle()
@property (nonatomic, copy) NSString *internalArticleID;
@end


@implementation RSParsedArticle

- (instancetype)initWithFeedURL:(NSURL *)feedURL dateParsed:(NSDate*)parsed {
	
	NSParameterAssert(feedURL != nil);
	
	self = [super init];
	if (self) {
		_feedURL = feedURL;
		_dateParsed = parsed;
	}
	return self;
}

#pragma mark - Unique Article ID

/**
 Article ID will be generated on the first access.
 */
- (NSString *)articleID {
	if (!_internalArticleID) {
		_internalArticleID = self.calculatedUniqueID;
	}
	return _internalArticleID;
}

/**
 Initiate calculation of article id.
 */
- (void)calculateArticleID {
	(void)self.articleID;
}

/**
 @return MD5 hash of @c feedURL @c + @c guid. Or a combination of properties when guid is not set.
 @note
 In general, feeds should have guids. When they don't, re-runs are very likely,
 because there's no other 100% reliable way to determine identity.
 */
- (NSString *)calculatedUniqueID {

	NSAssert(self.feedURL != nil, @"Feed URL should always be set!");
	NSMutableString *s = [NSMutableString stringWithFormat:@"%@", self.feedURL];
	
	if (self.guid.length > 0) {
		[s appendString:self.guid];
	}
	else if (self.datePublished != nil) {
		
		if (self.link.length > 0) {
			[s appendString:self.link];
		} else if (self.title.length > 0) {
			[s appendString:self.title];
		}
		[s appendString:[NSString stringWithFormat:@"%.0f", self.datePublished.timeIntervalSince1970]];
	}
	else if (self.link.length > 0) {
		[s appendString:self.link];
	}
	else if (self.title.length > 0) {
		[s appendString:self.title];
	}
	else if (self.body.length > 0) {
		[s appendString:self.body];
	}
	return [s rsxml_md5HashString];
}

#pragma mark - Printing

- (NSString*)description {
	return [NSString stringWithFormat:@"{%@ '%@', guid: %@}", [self class], self.title, self.guid];
}

@end

