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


@interface RSParsedArticle : NSObject

- (nonnull instancetype)initWithFeedURL:(NSURL * _Nonnull)feedURL dateParsed:(NSDate*)parsed;

@property (nonatomic, readonly, nonnull) NSURL *feedURL;
@property (nonatomic, readonly, nonnull) NSDate *dateParsed;
@property (nonatomic, readonly, nonnull) NSString *articleID; //Calculated. Don't get until other properties have been set.

@property (nonatomic, nullable) NSString *guid;
@property (nonatomic, nullable) NSString *title;
@property (nonatomic, nullable) NSString *abstract;
@property (nonatomic, nullable) NSString *body;
@property (nonatomic, nullable) NSString *link;
@property (nonatomic, nullable) NSString *permalink;
@property (nonatomic, nullable) NSString *author;
@property (nonatomic, nullable) NSDate *datePublished;
@property (nonatomic, nullable) NSDate *dateModified;

- (void)calculateArticleID; // Optimization. Call after all properties have been set. Call on a background thread.

@end

