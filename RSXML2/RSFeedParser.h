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

#import <RSXML2/RSXMLParser.h>

@class RSParsedFeed, RSParsedArticle;

/// Generic feed parser. Used for atom, RSS, and RDF feeds.
@interface RSFeedParser : RSXMLParser<RSParsedFeed*>
@property (nonatomic, readonly) RSParsedFeed *parsedFeed;
@property (nonatomic, weak) RSParsedArticle *currentArticle;

/// @return @c NSDate by parsing RFC 822 and 8601 date strings.
- (NSDate *)dateFromCharacters:(NSData *)data;
/// @return currentString by removing HTML encoded entities.
- (NSString *)decodeHTMLEntities:(NSString *)str;
@end
