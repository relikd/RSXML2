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

#import "RSParsedFeed.h"
#import "RSParsedArticle.h"

@interface RSParsedFeed()
@property (nonatomic) NSMutableArray <RSParsedArticle *> *mutableArticles;
@end

@implementation RSParsedFeed

- (instancetype)initWithURL:(NSURL *)url {
	
	self = [super init];
	if (self) {
		_url = url;
		_mutableArticles = [NSMutableArray new];
		_dateParsed = [NSDate date];
	}
	return self;
}

- (NSArray<RSParsedArticle *> *)articles {
	return _mutableArticles;
}

/**
 Append new @c RSParsedArticle object to @c .articles and return newly inserted instance.
 */
- (RSParsedArticle *)appendNewArticle {
	RSParsedArticle *article = [[RSParsedArticle alloc] initWithFeedURL:self.url dateParsed:_dateParsed];
	[_mutableArticles addObject:article];
	return article;
}

#pragma mark - Printing

- (NSString*)description {
	return [NSString stringWithFormat:@"{%@ (%@), title: '%@', subtitle: '%@', entries: %@}",
			[self class], _link, _title, _subtitle, _mutableArticles];
}

@end
