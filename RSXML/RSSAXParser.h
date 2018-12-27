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
#import <libxml/xmlstring.h>

/*Thread-safe, not re-entrant.

 Calls to the delegate will happen on the same thread where the parser runs.

 This is a low-level streaming XML parser, a thin wrapper for libxml2's SAX parser. It doesn't do much Foundation-ifying quite on purpose -- because the goal is performance and low memory use.

 This class is not meant to be sub-classed. Use the delegate methods.
 */


@class RSSAXParser;

@protocol RSSAXParserDelegate <NSObject>

+ (BOOL)isHTMLParser; // reusing class method of RSXMLParser delegate

@optional

// Called when parsing HTML
- (void)saxParser:(RSSAXParser *)SAXParser XMLStartElement:(const xmlChar *)localName attributes:(const xmlChar **)attributes;
- (void)saxParser:(RSSAXParser *)SAXParser XMLEndElement:(const xmlChar *)localName;

// Called when parsing XML (Atom, RSS, OPML)
- (void)saxParser:(RSSAXParser *)SAXParser XMLStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(NSInteger)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(NSInteger)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes;
- (void)saxParser:(RSSAXParser *)SAXParser XMLEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri;

// Called regardless of parser type
- (void)saxParser:(RSSAXParser *)SAXParser XMLCharactersFound:(const xmlChar *)characters length:(NSUInteger)length;
- (void)saxParserDidReachEndOfDocument:(RSSAXParser *)SAXParser; // If canceled, may not get called (but might).
- (NSString *)saxParser:(RSSAXParser *)SAXParser internedStringForName:(const xmlChar *)name prefix:(const xmlChar *)prefix; // Okay to return nil. Prefix may be nil.
- (NSString *)saxParser:(RSSAXParser *)SAXParser internedStringForValue:(const void *)bytes length:(NSUInteger)length;
@end



@interface RSSAXParser : NSObject
@property (nonatomic, strong, readonly) NSData *currentCharacters;
@property (nonatomic, strong, readonly) NSString *currentString;
@property (nonatomic, strong, readonly) NSString *currentStringWithTrimmedWhitespace;

- (instancetype)initWithDelegate:(id<RSSAXParserDelegate>)delegate;

- (void)parseBytes:(const void *)bytes numberOfBytes:(NSUInteger)numberOfBytes;
- (void)cancel;
- (void)beginStoringCharacters;

- (NSDictionary *)attributesDictionary:(const unsigned char **)attributes numberOfAttributes:(NSInteger)numberOfAttributes;
- (NSDictionary *)attributesDictionaryHTML:(const xmlChar **)attributes;

@end
