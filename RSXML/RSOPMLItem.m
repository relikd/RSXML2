
#import "RSOPMLItem.h"
#import "RSXMLInternal.h"


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
	if (self.attributes.count > 0 && !RSXMLStringIsEmpty(key)) {
		return [self.attributes rsxml_objectForCaseInsensitiveKey:key];
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
