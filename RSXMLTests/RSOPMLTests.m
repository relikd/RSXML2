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

#import <XCTest/XCTest.h>
@import RSXML;

@interface RSOPMLTests : XCTestCase

@end

@implementation RSOPMLTests

+ (NSArray<XCTPerformanceMetric> *)defaultPerformanceMetrics {
	return @[XCTPerformanceMetric_WallClockTime, @"com.apple.XCTPerformanceMetric_TotalHeapAllocationsKilobytes"];
}

- (RSXMLData*)xmlFile:(NSString*)name extension:(NSString*)ext {
	NSString *s = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:ext inDirectory:@"Resources"];
	if (s == nil) return nil;
	NSData *d = [[NSData alloc] initWithContentsOfFile:s];
	return [[RSXMLData alloc] initWithData:d urlString:[NSString stringWithFormat:@"%@.%@", name, ext]];
}

- (void)testNotOPML {

	NSError *error;
	RSXMLData *xmlData = [self xmlFile:@"DaringFireball" extension:@"atom"];
	XCTAssertNotEqualObjects(xmlData.parserClass, [RSOPMLParser class]);
	XCTAssertNil(xmlData.parserError);
	
	RSOPMLParser *parser = [[RSOPMLParser alloc] initWithXMLData:xmlData];
	RSOPMLItem *document = [parser parseSync:&error];
	XCTAssertNil(document);
	XCTAssertNotNil(error);
	XCTAssertEqual(error.code, RSXMLErrorExpectingOPML);
	XCTAssertEqualObjects(error.domain, kRSXMLParserErrorDomain);

	xmlData = [[RSXMLData alloc] initWithData:[[NSData alloc] initWithContentsOfFile:@"/System/Library/Kernels/kernel"]
									urlString:@"/System/Library/Kernels/kernel"];
	XCTAssertNotNil(xmlData.parserError);
	XCTAssert(xmlData.parserError.code == RSXMLErrorMissingLeftCaret);
	RSXMLParser *parser2 = [xmlData getParser];
	XCTAssertNil(parser2);
	XCTAssertNotNil(xmlData.parserError);
	XCTAssert(xmlData.parserError.code == RSXMLErrorMissingLeftCaret); // error should not be overwritten
	
}

- (void)testSubsStructure {

	RSXMLData<RSOPMLParser*> *xmlData = [self xmlFile:@"Subs" extension:@"opml"];
	XCTAssertEqualObjects(xmlData.parserClass, [RSOPMLParser class]);
	
	NSError *error;
	RSOPMLParser *parser = [xmlData getParser];
	RSOPMLItem *document = [parser parseSync:&error];
	XCTAssertNotNil(document);
	XCTAssertEqualObjects(document.displayName, @"Subs");
	XCTAssertEqualObjects(document.children.firstObject.displayName, @"Daring Fireball");
	XCTAssertEqualObjects(document.children.lastObject.displayName, @"Writers");
	XCTAssertEqualObjects(document.children.lastObject.children.lastObject.displayName, @"Gerrold");
	[self checkStructureForOPMLItem:document isRoot:YES];
	
	//NSLog(@"\n%@", [document recursiveDescription]);
	
	[self measureBlock:^{
		[parser parseSync:nil];
	}];
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
