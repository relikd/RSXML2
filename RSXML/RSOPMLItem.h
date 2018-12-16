
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

- (void)addChild:(RSOPMLItem *)child;
- (void)setAttribute:(id)value forKey:(NSString *)key;
- (id)attributeForKey:(NSString *)key;

- (NSString *)recursiveDescription;
@end
