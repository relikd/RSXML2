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

@interface RSHTMLTests : XCTestCase

@end

@implementation RSHTMLTests

+ (NSArray<XCTPerformanceMetric> *)defaultPerformanceMetrics {
	return @[XCTPerformanceMetric_WallClockTime, @"com.apple.XCTPerformanceMetric_TotalHeapAllocationsKilobytes"];
}

- (RSXMLData *)xmlData:(NSString *)title urlString:(NSString *)urlString {
	NSString *s = [[NSBundle bundleForClass:[self class]] pathForResource:title ofType:@"html" inDirectory:@"Resources"];
	return [[RSXMLData alloc] initWithData:[[NSData alloc] initWithContentsOfFile:s] url:[NSURL URLWithString:urlString]];
}

- (void)testDaringFireball {

	RSXMLData *xmlData = [self xmlData:@"DaringFireball" urlString:@"http://daringfireball.net/"];
	XCTAssertTrue([xmlData.parserClass isHTMLParser]);
	RSHTMLMetadataParser *parser = [RSHTMLMetadataParser parserWithXMLData:xmlData];
	NSError *error;
	RSHTMLMetadata *metadata = [parser parseSync:&error];
	XCTAssertNil(error);
	XCTAssertEqualObjects(metadata.faviconLink, @"http://daringfireball.net/graphics/favicon.ico?v=005");

	XCTAssertTrue(metadata.feedLinks.count == 1);
	RSHTMLMetadataFeedLink *feedLink = metadata.feedLinks[0];
	XCTAssertNil(feedLink.title);
	XCTAssertEqual(feedLink.type, RSFeedTypeAtom);
	XCTAssertEqualObjects(feedLink.link, @"http://daringfireball.net/feeds/main");
	
	[self measureBlock:^{
		for (int i = 0; i < 10; i++)
			[parser parseSync:nil];
	}];
}

- (void)testFurbo {

	RSXMLData *xmlData = [self xmlData:@"furbo" urlString:@"http://furbo.org/"];
	XCTAssertTrue([xmlData.parserClass isHTMLParser]);
	RSHTMLMetadataParser *parser = [RSHTMLMetadataParser parserWithXMLData:xmlData];
	NSError *error;
	RSHTMLMetadata *metadata = [parser parseSync:&error];
	XCTAssertNil(error);
	XCTAssertEqualObjects(metadata.faviconLink, @"http://furbo.org/favicon.ico");

	XCTAssertTrue(metadata.feedLinks.count == 1);
	RSHTMLMetadataFeedLink *feedLink = metadata.feedLinks[0];
	XCTAssertEqualObjects(feedLink.title, @"Iconfactory News Feed");
	XCTAssertEqual(feedLink.type, RSFeedTypeRSS);
	
	[self measureBlock:^{
		for (int i = 0; i < 10; i++)
			[parser parseSync:nil];
	}];
}

- (void)testInessential {

	RSXMLData *xmlData = [self xmlData:@"inessential" urlString:@"http://inessential.com/"];
	XCTAssertTrue([xmlData.parserClass isHTMLParser]);
	RSHTMLMetadataParser *parser = [RSHTMLMetadataParser parserWithXMLData:xmlData];
	NSError *error;
	RSHTMLMetadata *metadata = [parser parseSync:&error];
	XCTAssertNil(error);
	XCTAssertNil(metadata.faviconLink);

	XCTAssertTrue(metadata.feedLinks.count == 1);
	RSHTMLMetadataFeedLink *feedLink = metadata.feedLinks[0];
	XCTAssertEqualObjects(feedLink.title, @"RSS");
	XCTAssertEqual(feedLink.type, RSFeedTypeRSS);
	XCTAssertEqualObjects(feedLink.link, @"http://inessential.com/xml/rss.xml");

	XCTAssertEqual(metadata.iconLinks.count, 0u);
	
	[self measureBlock:^{
		for (int i = 0; i < 10; i++)
			[parser parseSync:nil];
	}];
}

- (void)testSixcolors {

	RSXMLData *xmlData = [self xmlData:@"sixcolors" urlString:@"https://sixcolors.com/"];
	XCTAssertTrue([xmlData.parserClass isHTMLParser]);
	RSHTMLMetadataParser *parser = [RSHTMLMetadataParser parserWithXMLData:xmlData];
	NSError *error;
	RSHTMLMetadata *metadata = [parser parseSync:&error];
	XCTAssertNil(error);

	XCTAssertEqualObjects(metadata.faviconLink, @"https://sixcolors.com/images/favicon.ico");

	XCTAssertTrue(metadata.feedLinks.count == 1);
	RSHTMLMetadataFeedLink *feedLink = metadata.feedLinks[0];
	XCTAssertEqualObjects(feedLink.title, @"RSS");
	XCTAssertEqual(feedLink.type, RSFeedTypeRSS);
	XCTAssertEqualObjects(feedLink.link, @"http://feedpress.me/sixcolors");

	XCTAssertEqual(metadata.iconLinks.count, 6u);
	RSHTMLMetadataIconLink *icon = metadata.iconLinks[3];
	XCTAssertEqualObjects(icon.title, @"apple-touch-icon");
	XCTAssertEqualObjects(icon.sizes, @"120x120");
	XCTAssertEqual([icon getSize].width, 120);
	XCTAssertEqualObjects(icon.link, @"https://sixcolors.com/apple-touch-icon-120.png");
	
	[self measureBlock:^{
		for (int i = 0; i < 10; i++)
			[parser parseSync:nil];
	}];
}

#pragma mark - Links

- (void)testSixColorsLinks {

	RSXMLData *xmlData = [self xmlData:@"sixcolors" urlString:@"https://sixcolors.com/"];
	XCTAssertTrue([xmlData.parserClass isHTMLParser]);
	RSHTMLLinkParser *parser = [RSHTMLLinkParser parserWithXMLData:xmlData];
	NSError *error;
	NSArray<RSHTMLMetadataAnchor*> *links = [parser parseSync:&error];
	XCTAssertNil(error);
	
	BOOL found = NO;
	for (RSHTMLMetadataAnchor *oneLink in links) {
		if ([oneLink.title isEqualToString:@"this week’s episode of The Incomparable"] &&
			[oneLink.link isEqualToString:@"https://www.theincomparable.com/theincomparable/290/index.php"])
		{
			found = YES;
			break;
		}
	}
	// item No 11 to ensure .text removes <em></em>
	XCTAssertEqualObjects(links[11].title, @"Podcasting");
	XCTAssertEqualObjects(links[11].link, @"https://sixcolors.com/topic/podcasting/");
	// item No. 18 & 19 to ensure '<a>Topics</a>' is skipped
	XCTAssertEqualObjects(links[18].title, @"Podcasts");
	XCTAssertEqualObjects(links[18].link, @"https://sixcolors.com/podcasts/");
	XCTAssertEqualObjects(links[19].title, @"Gift Guide");
	XCTAssertEqualObjects(links[19].link, @"https://sixcolors.com/topic/giftguide/");
	XCTAssertTrue(found, @"Expected link should have been found.");
	XCTAssertEqual(links.count, 130u, @"Expected 130 links.");
	
	[self measureBlock:^{
		[parser parseSync:nil];
	}];
}

@end

