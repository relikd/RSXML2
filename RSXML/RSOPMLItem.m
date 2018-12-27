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

- (NSArray *)children {
	return [self.mutableChildren copy];
}

- (void)setChildren:(NSArray<RSOPMLItem*>*)children {
	self.mutableChildren = [children mutableCopy];
}

- (NSDictionary *)attributes {
	return [self.mutableAttributes copy];
}

- (void)setAttributes:(NSDictionary *)attributes {
	self.mutableAttributes = [attributes mutableCopy];
}

- (BOOL)isFolder {
	return self.mutableChildren.count > 0;
}

- (NSString *)displayName {
	NSString *title = [self attributeForKey:OPMLTitleKey];
	if (!title) {
		title = [self attributeForKey:OPMLTextKey];
	}
	return title;
}

- (void)addChild:(RSOPMLItem *)child {
	if (!self.mutableChildren) {
		self.mutableChildren = [NSMutableArray new];
	}
	[self.mutableChildren addObject:child];
}

- (void)setAttribute:(id)value forKey:(NSString *)key {
	if (!self.mutableAttributes) {
		self.mutableAttributes = [NSMutableDictionary new];
	}
	[self.mutableAttributes setValue:value forKey:key];
}

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

- (void)appendStringRecursive:(NSMutableString *)str indent:(NSString *)prefix {
	[str appendFormat:@"%@%@\n", prefix, self];
	if (self.isFolder) {
		for (RSOPMLItem *child in self.children) {
			[child appendStringRecursive:str indent:[prefix stringByAppendingString:@"  "]];
		}
		[str appendFormat:@"%@</group>\n", prefix];
	}
}

- (NSString *)recursiveDescription {
	NSMutableString *mStr = [NSMutableString new];
	[self appendStringRecursive:mStr indent:@""];
	return mStr;
}

@end
