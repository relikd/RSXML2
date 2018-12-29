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

// OPML allows for arbitrary attributes.
// These are the common attributes in OPML files used as RSS subscription lists.

extern NSString *OPMLTextKey; //text
extern NSString *OPMLTitleKey; //title
extern NSString *OPMLDescriptionKey; //description
extern NSString *OPMLTypeKey; //type
extern NSString *OPMLVersionKey; //version
extern NSString *OPMLHMTLURLKey; //htmlUrl
extern NSString *OPMLXMLURLKey; //xmlUrl


@interface RSOPMLItem : NSObject
@property (nonatomic) NSArray<RSOPMLItem*> *children;
@property (nonatomic) NSDictionary *attributes;
@property (nonatomic, readonly) BOOL isFolder; // true if children.count > 0
@property (nonatomic, readonly) NSString *displayName; //May be nil.

+ (instancetype)itemWithAttributes:(NSDictionary *)attribs;

- (void)addChild:(RSOPMLItem *)child;
- (void)setAttribute:(id)value forKey:(NSString *)key;
- (id)attributeForKey:(NSString *)key;

- (NSString *)recursiveDescription;
- (NSString *)exportOPMLAsString;
@end
