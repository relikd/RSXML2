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

NS_ASSUME_NONNULL_BEGIN

//  ---------------------------------------------------------------
// |  MARK: - Parser Delegate
//  ---------------------------------------------------------------

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
- (nullable id)xmlParserWillReturnDocument;
@end


//  ---------------------------------------------------------------
// |  MARK: - Parser
//  ---------------------------------------------------------------

/**
 Generic wrapper class for @c libxml parsing.
 Could be one of @c RSRSSParser, @c RSAtomParser, @c RSOPMLParser, @c RSHTMLMetadataParser, and @c RSHTMLLinkParser
 */
@interface RSXMLParser<__covariant T> : NSObject <RSXMLParserDelegate, RSSAXParserDelegate>
@property (nonatomic, readonly, nonnull, copy) NSURL *documentURI;
@property (nonatomic, assign) BOOL dontStopOnLowerAsciiBytes;

/**
 Designated initializer. Runs a check whether it matches the detected parser in @c RSXMLData.
 Keeps an internal pointer to the @c RSXMLData and initializes a new @c RSSAXParser.
 */
+ (instancetype)parserWithXMLData:(RSXMLData * _Nonnull)xmlData;

/**
 Parse the XML data on whatever thread this method is called.
 
 @param error Sets @c error if parser gets unrecognized data or @c libxml runs into a parsing error.
 @return The parsed object. The object type depends on the underlying data. @c RSParsedFeed, @c RSOPMLItem or @c RSHTMLMetadata.
 */
- (T _Nullable)parseSync:(NSError ** _Nullable)error;
/// Dispatch new background thread, parse the data synchroniously on the background thread and exec callback on the main thread.
- (void)parseAsync:(void(^)(T _Nullable parsedDocument, NSError * _Nullable error))block;
/// @return @c YES if @c .xmlInputError is @c nil.
- (BOOL)canParse;

@end

NS_ASSUME_NONNULL_END
