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

#ifndef TARGET_IOS
#define OPML_EXPORT 0
#endif

NS_ASSUME_NONNULL_BEGIN

// OPML allows for arbitrary attributes.
// These are the common attributes in OPML files used as RSS subscription lists.

/** Constant: @c \@"text"        */ extern NSString *OPMLTextKey;
/** Constant: @c \@"title"       */ extern NSString *OPMLTitleKey;
/** Constant: @c \@"description" */ extern NSString *OPMLDescriptionKey;
/** Constant: @c \@"type"        */ extern NSString *OPMLTypeKey;
/** Constant: @c \@"version"     */ extern NSString *OPMLVersionKey;
/** Constant: @c \@"htmlUrl"     */ extern NSString *OPMLHMTLURLKey;
/** Constant: @c \@"xmlUrl"      */ extern NSString *OPMLXMLURLKey;


/// Parsed result type for opml files. @c children can be arbitrary nested.
@interface RSOPMLItem : NSObject
/// Can be arbitrary nested.
@property (nonatomic) NSArray<RSOPMLItem*> *children;
@property (nonatomic) NSDictionary *attributes;
/// Returns @c YES if @c children.count @c > @c 0
@property (nonatomic, readonly) BOOL isFolder;
@property (nonatomic, readonly, nullable) NSString *displayName;

+ (instancetype)itemWithAttributes:(NSDictionary *)attribs;

/// Appends one child to the internal children array (creates new empty array if necessary).
- (void)addChild:(RSOPMLItem *)child;
/// Sets a value in the internal dictionary (creates new empty dictionary if necessary).
- (void)setAttribute:(id)value forKey:(NSString *)key;
/// @return Value for key (case-independent).
- (nullable id)attributeForKey:(NSString *)key;

/// Print object description for debugging purposes.
- (NSString *)recursiveDescription;
#if OPML_EXPORT
/// Can be used to export directly to @c .opml file.
- (NSXMLDocument *)exportXML;
#endif
@end

NS_ASSUME_NONNULL_END
