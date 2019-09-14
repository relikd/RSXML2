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

#import "RSOPMLItem.h"
#import "NSDictionary+RSXML.h"


NSString *OPMLTextKey = @"text";
NSString *OPMLTitleKey = @"title";
NSString *OPMLDescriptionKey = @"description";
NSString *OPMLTypeKey = @"type";
NSString *OPMLVersionKey = @"version";
NSString *OPMLHMTLURLKey = @"htmlUrl";
NSString *OPMLXMLURLKey = @"xmlUrl";


@interface RSOPMLItem ()
@property (nonatomic) NSMutableArray<RSOPMLItem*> *mutableChildren;
@property (nonatomic) NSMutableDictionary *mutableAttributes;
@end


@implementation RSOPMLItem

+ (instancetype)itemWithAttributes:(NSDictionary *)attribs {
	RSOPMLItem *item = [[super alloc] init];
	[item setAttributes:attribs];
	return item;
}

/// @return A copy of the internal array.
- (NSArray *)children {
	return [self.mutableChildren copy];
}

/// Replace internal array with new one.
- (void)setChildren:(NSArray<RSOPMLItem*>*)children {
	self.mutableChildren = [children mutableCopy];
}

/// @return A copy of the internal dictionary.
- (NSDictionary *)attributes {
	return [self.mutableAttributes copy];
}

/// Replace internal dictionary with new one.
- (void)setAttributes:(NSDictionary *)attributes {
	self.mutableAttributes = [attributes mutableCopy];
}

/// @return @c YES if @c children.count @c > @c 0.
- (BOOL)isFolder {
	return self.mutableChildren.count > 0;
}

/// @return Value for @c OPMLTitleKey. If not set, use @c OPMLTextKey, else return @c nil.
- (nullable NSString *)displayName {
	NSString *title = [self attributeForKey:OPMLTitleKey];
	if (!title) {
		title = [self attributeForKey:OPMLTextKey];
	}
	return title;
}

// docref in header
- (void)addChild:(RSOPMLItem *)child {
	if (!self.mutableChildren) {
		self.mutableChildren = [NSMutableArray new];
	}
	[self.mutableChildren addObject:child];
}

// docref in header
- (void)setAttribute:(id)value forKey:(NSString *)key {
	if (!self.mutableAttributes) {
		self.mutableAttributes = [NSMutableDictionary new];
	}
	[self.mutableAttributes setValue:value forKey:key];
}

// docref in header
- (id)attributeForKey:(NSString *)key {
	if (self.mutableAttributes.count > 0 && key && key.length > 0) {
		return [self.mutableAttributes rsxml_objectForCaseInsensitiveKey:key];
	}
	return nil;
}

#pragma mark - Printing

- (NSString *)description {
	NSMutableString *str = [NSMutableString stringWithFormat:@"<%@ group: %d", [self class], self.isFolder];
	for (NSString *key in _mutableAttributes) {
		[str appendFormat:@", %@: '%@'", key, _mutableAttributes[key]];
	}
	[str appendString:@">"];
	return str;
}

/// Used by @c recursiveDescription.
- (void)appendStringRecursive:(NSMutableString *)str indent:(NSString *)prefix {
	[str appendFormat:@"%@%@\n", prefix, self];
	if (self.isFolder) {
		for (RSOPMLItem *child in self.children) {
			[child appendStringRecursive:str indent:[prefix stringByAppendingString:@"  "]];
		}
		[str appendFormat:@"%@</group>\n", prefix];
	}
}

// docref in header
- (NSString *)recursiveDescription {
	NSMutableString *mStr = [NSMutableString new];
	[self appendStringRecursive:mStr indent:@""];
	return mStr;
}

#if OPML_EXPORT

// docref in header
- (NSXMLDocument *)exportXML {
	NSXMLElement *head = [NSXMLElement elementWithName:@"head"];
	for (NSString *key in _mutableAttributes) {
		NSString *val = [NSString stringWithFormat:@"%@", _mutableAttributes[key]];
		[head addChild:[NSXMLElement elementWithName:key stringValue:val]];
	}
	
	NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
	for (RSOPMLItem *child in _mutableChildren) {
		[child appendChildToNode:body];
	}
	
	NSXMLElement *opml = [NSXMLElement elementWithName:@"opml"];
	[opml addAttribute:[NSXMLNode attributeWithName:@"version" stringValue:@"1.0"]];
	[opml addChild:head];
	[opml addChild:body];
	
	NSXMLDocument *xml = [NSXMLDocument documentWithRootElement:opml];
	xml.version = @"1.0";
	xml.characterEncoding = @"UTF-8";
	return xml;
}

/// Recursively add XMLNode children.
- (void)appendChildToNode:(NSXMLElement *)parent {
	NSXMLElement *outline = [NSXMLElement elementWithName:@"outline"];
	[parent addChild:outline];
	NSString *name = [self displayName];
	[outline addAttribute:[NSXMLNode attributeWithName:OPMLTitleKey stringValue:name]];
	[outline addAttribute:[NSXMLNode attributeWithName:OPMLTextKey stringValue:name]];
	[outline setAttributesAsDictionary:_mutableAttributes];
	for (RSOPMLItem *child in _mutableChildren) {
		[child appendChildToNode:outline];
	}
}

#endif

@end
