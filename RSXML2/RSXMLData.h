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
#import "RSXMLParser.h"

NS_ASSUME_NONNULL_BEGIN

@class RSXMLParser;

/// Wrapper class for xml data. Returns the designated parser for any given xml data.
@interface RSXMLData <__covariant T : RSXMLParser *> : NSObject
@property (nonatomic, readonly, nonnull) NSURL *url;
@property (nonatomic, readonly, nullable) NSData *data;
@property (nonatomic, readonly, nullable) Class parserClass;
@property (nonatomic, readonly, nullable) NSError *parserError;

- (instancetype)initWithData:(NSData * _Nonnull)data url:(NSURL * _Nonnull)url;

/// @return Kind of @c RSXMLParser or @c nil if no suitable parser found.
- (T _Nullable)getParser;
/// @return @c YES if any parser, regardless of type, is suitable.
- (BOOL)canParseData;

@end

NS_ASSUME_NONNULL_END
