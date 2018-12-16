//
//  RSOPMLTests.m
//  RSXML
//
//  Created by Brent Simmons on 2/28/16.
//  Copyright © 2016 Ranchero Software, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
@import RSXML;

@interface RSOPMLTests : XCTestCase

@end

@implementation RSOPMLTests

+ (RSXMLData *)subsData {

	static RSXMLData *xmlData = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *s = [[NSBundle bundleForClass:[self class]] pathForResource:@"Subs" ofType:@"opml" inDirectory:@"Resources"];
		NSData *d = [[NSData alloc] initWithContentsOfFile:s];
		xmlData = [[RSXMLData alloc] initWithData:d urlString:@"http://example.org/"];
	});

	return xmlData;
}

- (void)testNotOPML {

	NSString *s = [[NSBundle bundleForClass:[self class]] pathForResource:@"DaringFireball" ofType:@"rss" inDirectory:@"Resources"];
	NSData *d = [[NSData alloc] initWithContentsOfFile:s];
	RSXMLData *xmlData = [[RSXMLData alloc] initWithData:d urlString:@"http://example.org/"];
	RSOPMLParser *parser = [[RSOPMLParser alloc] initWithXMLData:xmlData];
	XCTAssertNotNil(parser.error);
	XCTAssert(parser.error.code == RSXMLErrorFileNotOPML);
	XCTAssert([parser.error.domain isEqualTo:kRSXMLParserErrorDomain]);

	d = [[NSData alloc] initWithContentsOfFile:@"/System/Library/Kernels/kernel"];
	xmlData = [[RSXMLData alloc] initWithData:d urlString:@"/System/Library/Kernels/kernel"];
	parser = [[RSOPMLParser alloc] initWithXMLData:xmlData];
	XCTAssertNotNil(parser.error);
}


- (void)testSubsPerformance {

	RSXMLData *xmlData = [[self class] subsData];

	[self measureBlock:^{
		(void)[[RSOPMLParser alloc] initWithXMLData:xmlData];
	}];
}


- (void)testSubsStructure {

	RSXMLData *xmlData = [[self class] subsData];

	RSOPMLParser *parser = [[RSOPMLParser alloc] initWithXMLData:xmlData];
	XCTAssertNotNil(parser);

	RSOPMLItem *document = parser.opmlDocument;
	XCTAssertNotNil(document);
	XCTAssert([document.displayName isEqualToString:@"Subs"]);
	XCTAssert([document.children.firstObject.displayName isEqualToString:@"Daring Fireball"]);
	XCTAssert([document.children.lastObject.displayName isEqualToString:@"Writers"]);
	XCTAssert([document.children.lastObject.children.lastObject.displayName isEqualToString:@"Gerrold"]);
	[self checkStructureForOPMLItem:document isRoot:YES];
	
	//NSLog(@"\n%@", [document recursiveDescription]);
}

- (void)checkStructureForOPMLItem:(RSOPMLItem *)item isRoot:(BOOL)root {

	if (!root) {
		XCTAssertNotNil([item attributeForKey:OPMLTextKey]);
		XCTAssertNotNil([item attributeForKey:OPMLTitleKey]);
	}

	// If it has no children, it should have a feed specifier. The converse is also true.
	BOOL isFolder = (item.children.count > 0);
	if (!isFolder && [[item attributeForKey:OPMLTitleKey] isEqualToString:@"Skip"]) {
		isFolder = YES;
	}

	if (!isFolder) {
		XCTAssertNotNil([item attributeForKey:OPMLHMTLURLKey]);
	}

	if (item.children.count > 0) {
		for (RSOPMLItem *oneItem in item.children) {
			[self checkStructureForOPMLItem:oneItem isRoot:NO];
		}
	}
}


@end
