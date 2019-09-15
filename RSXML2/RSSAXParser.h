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

/*Thread-safe, not re-entrant.

 Calls to the delegate will happen on the same thread where the parser runs.

 This is a low-level streaming XML parser, a thin wrapper for libxml2's SAX parser. It doesn't do much Foundation-ifying quite on purpose -- because the goal is performance and low memory use.

 This class is not meant to be sub-classed. Use the delegate methods.
 */


@class RSSAXParser;

/// Use @c xmlChar instead of @c unsigned @c char for all method parameters.
@protocol RSSAXParserDelegate <NSObject>

+ (BOOL)isHTMLParser; // reusing class method of RSXMLParser delegate

@optional

// Called when parsing HTML
- (void)saxParser:(RSSAXParser *)SAXParser XMLStartElement:(const unsigned char *)localName attributes:(const unsigned char **)attributes;
- (void)saxParser:(RSSAXParser *)SAXParser XMLEndElement:(const unsigned char *)localName;

// Called when parsing XML (Atom, RSS, OPML)
- (void)saxParser:(RSSAXParser *)SAXParser XMLStartElement:(const unsigned char *)localName prefix:(const unsigned char *)prefix uri:(const unsigned char *)uri numberOfNamespaces:(NSInteger)numberOfNamespaces namespaces:(const unsigned char **)namespaces numberOfAttributes:(NSInteger)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const unsigned char **)attributes;
- (void)saxParser:(RSSAXParser *)SAXParser XMLEndElement:(const unsigned char *)localName prefix:(const unsigned char *)prefix uri:(const unsigned char *)uri;

// Called regardless of parser type
- (void)saxParser:(RSSAXParser *)SAXParser XMLCharactersFound:(const unsigned char *)characters length:(NSUInteger)length;
- (void)saxParserDidReachEndOfDocument:(RSSAXParser *)SAXParser; // If canceled, may not get called (but might).
- (NSString *)saxParser:(RSSAXParser *)SAXParser internedStringForName:(const unsigned char *)name prefix:(const unsigned char *)prefix; // Okay to return nil. Prefix may be nil.
- (NSString *)saxParser:(RSSAXParser *)SAXParser internedStringForValue:(const void *)bytes length:(NSUInteger)length;
@end



@interface RSSAXParser : NSObject
@property (nonatomic, strong, readonly) NSError *parsingError;
@property (nonatomic, strong, readonly) NSData *currentCharacters;
@property (nonatomic, strong, readonly) NSString *currentString;
@property (nonatomic, strong, readonly) NSString *currentStringWithTrimmedWhitespace;

- (instancetype)initWithDelegate:(id<RSSAXParserDelegate>)delegate;

/// Initialize new xml or html parser context and start processing of data.
- (void)parseBytes:(const void *)bytes numberOfBytes:(NSUInteger)numberOfBytes;
/// Will stop the sax parser from processing any further. @c saxParserDidReachEndOfDocument: will not be called.
- (void)cancel;
/**
 Delegate can call from @c XMLStartElement.
 Characters will be available in @c XMLEndElement as @c currentCharacters property.
 Storing characters is stopped after each @c XMLEndElement.
 */
- (void)beginStoringCharacters;

/// Delegate can call from within @c XMLStartElement. Returns @c nil if @c numberOfAttributes @c < @c 1 .
- (NSDictionary *)attributesDictionary:(const unsigned char **)attributes numberOfAttributes:(NSInteger)numberOfAttributes;
/// Delegate can call from within @c XMLStartElement. Returns @c nil if @c attributes is @c nil .
- (NSDictionary *)attributesDictionaryHTML:(const unsigned char **)attributes;

@end
