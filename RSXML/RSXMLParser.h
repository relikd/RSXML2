//
//  MIT License (MIT)
//
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
#import "RSSAXParser.h"

#define EqualBytes(bytes1, bytes2, length) (memcmp(bytes1, bytes2, length) == 0)
//#define EqualBytes(bytes1, bytes2, length) (!strncmp(bytes1, bytes2, length))

@class RSXMLData;


@protocol RSXMLParserDelegate <NSObject>
@optional
/**
 A subclass may return a list of tags that the data @c (RSXMLData) should include.
 Only if all strings are found (in correct order) the parser will be selected.
 
 @note This method will only be called if the original data has some weird encoding.
 @c RSXMLData will first try to convert the data to an @c UTF8 string, then @c UTF16.
 If both conversions fail the parser will be deemed as not suitable for this data.
 */
+ (NSArray<const NSString *> *)parserRequireOrderedTags;
/// @return Return @c NO to cancel parsing before it even started. E.g. check if parser is of correct type.
- (BOOL)xmlParserWillStartParsing;

@required
/// @return @c YES if parser supports parsing feeds (RSS or Atom).
+ (BOOL)isFeedParser;
/// @return @c YES if parser supports parsing OPML files.
+ (BOOL)isOPMLParser;
/// @return @c YES if parser supports parsing HTML files.
+ (BOOL)isHTMLParser;
/// Will be called after the parsing is finished. @return Reference to parsed object.
- (id)xmlParserWillReturnDocument;
@end


@interface RSXMLParser<__covariant T> : NSObject <RSXMLParserDelegate, RSSAXParserDelegate>
@property (nonatomic, readonly, nonnull, copy) NSURL *documentURI;
@property (nonatomic, assign) BOOL dontStopOnLowerAsciiBytes;

+ (instancetype)parserWithXMLData:(RSXMLData * _Nonnull)xmlData;

- (T _Nullable)parseSync:(NSError ** _Nullable)error;
- (void)parseAsync:(void(^)(T _Nullable parsedDocument, NSError * _Nullable error))block;
- (BOOL)canParse;

@end

