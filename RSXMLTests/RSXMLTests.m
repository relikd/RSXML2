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

@interface RSXMLTests : XCTestCase

@end

@implementation RSXMLTests

/** @see https://indiestack.com/2018/02/xcodes-secret-performance-tests/
 
 "com.apple.XCTPerformanceMetric_WallClockTime"
 "com.apple.XCTPerformanceMetric_UserTime"
 "com.apple.XCTPerformanceMetric_RunTime"
 "com.apple.XCTPerformanceMetric_SystemTime"
 "com.apple.XCTPerformanceMetric_HighWaterMarkForHeapAllocations"
 "com.apple.XCTPerformanceMetric_HighWaterMarkForVMAllocations"
 "com.apple.XCTPerformanceMetric_PersistentHeapAllocations"
 "com.apple.XCTPerformanceMetric_PersistentHeapAllocationsNodes"
 "com.apple.XCTPerformanceMetric_PersistentVMAllocations"
 "com.apple.XCTPerformanceMetric_TemporaryHeapAllocationsKilobytes"
 "com.apple.XCTPerformanceMetric_TotalHeapAllocationsKilobytes"
 "com.apple.XCTPerformanceMetric_TransientHeapAllocationsKilobytes"
 "com.apple.XCTPerformanceMetric_TransientHeapAllocationsNodes"
 "com.apple.XCTPerformanceMetric_TransientVMAllocationsKilobytes"
 */
+ (NSArray<XCTPerformanceMetric> *)defaultPerformanceMetrics {
	return @[XCTPerformanceMetric_WallClockTime, @"com.apple.XCTPerformanceMetric_TotalHeapAllocationsKilobytes"];
}

// http://onefoottsunami.com/
// http://scripting.com/
// http://manton.org/
// http://daringfireball.net/
// http://katiefloyd.com/
// https://medium.com/@emarley

- (RSXMLData*)xmlFile:(NSString*)name extension:(NSString*)ext {
	NSString *s = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:ext inDirectory:@"Resources"];
	if (s == nil) return nil;
	NSData *d = [[NSData alloc] initWithContentsOfFile:s];
	return [[RSXMLData alloc] initWithData:d url:[NSURL fileURLWithPath:s]];
}

- (RSFeedParser*)parserForFile:(NSString*)name extension:(NSString*)ext expect:(Class)cls {
	RSXMLData<RSFeedParser*> *xmlData = [self xmlFile:name extension:ext];
	XCTAssertEqual(xmlData.parserClass, cls);
	return [xmlData getParser];
}

#pragma mark - Completeness Tests

- (void)testAsync {
	RSXMLData *xmlData = [self xmlFile:@"OneFootTsunami" extension:@"atom"];
	[[xmlData getParser] parseAsync:^(RSParsedFeed *parsedDocument, NSError *error) {
		XCTAssertEqualObjects(parsedDocument.title, @"One Foot Tsunami");
		XCTAssertEqualObjects(parsedDocument.subtitle, @"Slightly less disappointing than it sounds");
		XCTAssertEqualObjects(parsedDocument.link, @"http://onefoottsunami.com");
		XCTAssertEqual(parsedDocument.articles.count, 25u);
		
		RSParsedArticle *a = parsedDocument.articles.firstObject;
		XCTAssertEqualObjects(a.title, @"Link: Pillow Fight Leaves 24 Concussed");
		XCTAssertEqualObjects(a.link, @"http://www.nytimes.com/2015/09/05/us/at-west-point-annual-pillow-fight-becomes-weaponized.html?mwrsm=Email&_r=1&pagewanted=all");
		XCTAssertEqualObjects(a.guid, @"http://onefoottsunami.com/?p=14863");
		XCTAssertEqual(a.datePublished, [NSDate dateWithTimeIntervalSince1970:1441722101]); // 2015-09-08T14:21:41Z
	}];
}

- (void)testOneFootTsunami {

	RSXMLData *xmlData = [self xmlFile:@"OneFootTsunami" extension:@"atom"];
	XCTAssertEqual(xmlData.parserClass, [RSAtomParser class]);
	
	NSError *error = nil;
	RSParsedFeed *parsedFeed = [[xmlData getParser] parseSync:&error];
	XCTAssertEqualObjects(parsedFeed.title, @"One Foot Tsunami");
	XCTAssertEqualObjects(parsedFeed.subtitle, @"Slightly less disappointing than it sounds");
	XCTAssertEqualObjects(parsedFeed.link, @"http://onefoottsunami.com");
	XCTAssertEqual(parsedFeed.articles.count, 25u);
	
	RSParsedArticle *a = parsedFeed.articles.firstObject;
	XCTAssertEqualObjects(a.title, @"Link: Pillow Fight Leaves 24 Concussed");
	XCTAssertEqualObjects(a.link, @"http://www.nytimes.com/2015/09/05/us/at-west-point-annual-pillow-fight-becomes-weaponized.html?mwrsm=Email&_r=1&pagewanted=all");
	XCTAssertEqualObjects(a.guid, @"http://onefoottsunami.com/?p=14863");
	XCTAssertEqual(a.datePublished, [NSDate dateWithTimeIntervalSince1970:1441722101]); // 2015-09-08T14:21:41Z
	
	[self measureBlock:^{
		[[xmlData getParser] parseSync:nil];
	}];
}


- (void)testScriptingNews {

	RSXMLData *xmlData = [self xmlFile:@"scriptingNews" extension:@"rss"];
	XCTAssertEqual(xmlData.parserClass, [RSRSSParser class]);
	
	NSError *error = nil;
	RSParsedFeed *parsedFeed = [[xmlData getParser] parseSync:&error];
	XCTAssertEqualObjects(parsedFeed.title, @"Scripting News");
	XCTAssertEqualObjects(parsedFeed.subtitle, @"Scripting News, the weblog started in 1997 that bootstrapped the blogging revolution...");
	XCTAssertEqualObjects(parsedFeed.link, @"http://scripting.com/");
	XCTAssertEqual(parsedFeed.articles.count, 25u);
	
	RSParsedArticle *a = parsedFeed.articles.firstObject;
	XCTAssertEqualObjects(a.title, @"People don't click links, that's why the 140-char limit will cripple Twitter");
	XCTAssertEqualObjects(a.link, @"http://scripting.com/2015/09/08/peopleDontClickLinks.html");
	XCTAssertEqualObjects(a.guid, @"http://scripting.com/2015/09/08/peopleDontClickLinks.html");
	XCTAssertEqual(a.datePublished, [NSDate dateWithTimeIntervalSince1970:1441723501]); // Tue Sep  8 16:45:01 2015
	
	[self measureBlock:^{
		[[xmlData getParser] parseSync:nil];
	}];
}


- (void)testManton {

	RSXMLData *xmlData = [self xmlFile:@"manton" extension:@"rss"];
	XCTAssertEqual(xmlData.parserClass, [RSRSSParser class]);
	
	NSError *error = nil;
	RSParsedFeed *parsedFeed = [[xmlData getParser] parseSync:&error];
	XCTAssertEqualObjects(parsedFeed.title, @"Manton Reece");
	XCTAssertNil(parsedFeed.subtitle);
	XCTAssertEqualObjects(parsedFeed.link, @"http://www.manton.org");
	XCTAssertEqual(parsedFeed.articles.count, 10u);
	
	RSParsedArticle *a = parsedFeed.articles.firstObject;
	XCTAssertNil(a.title);
	XCTAssertEqualObjects(a.link, @"http://www.manton.org/2015/09/3071.html");
	XCTAssertEqualObjects(a.guid, @"http://www.manton.org/?p=3071");
	XCTAssertEqual(a.datePublished, [NSDate dateWithTimeIntervalSince1970:1443191200]); // Fri, 25 Sep 2015 14:26:40 +0000
	
	[self measureBlock:^{
		[[xmlData getParser] parseSync:nil];
	}];
}


- (void)testKatieFloyd {

	RSXMLData *xmlData = [self xmlFile:@"KatieFloyd" extension:@"rss"];
	XCTAssertEqual(xmlData.parserClass, [RSRSSParser class]);
	
	NSError *error = nil;
	RSParsedFeed *parsedFeed = [[xmlData getParser] parseSync:&error];
	XCTAssertEqualObjects(parsedFeed.title, @"Katie Floyd");
	XCTAssertNil(parsedFeed.subtitle);
	XCTAssertEqualObjects(parsedFeed.link, @"http://www.katiefloyd.com");
	XCTAssertEqual(parsedFeed.articles.count, 20u);
	
	RSParsedArticle *a = parsedFeed.articles.firstObject;
	XCTAssertEqualObjects(a.title, @"Special Mac Power Users for Relay FM Members");
	XCTAssertEqualObjects(a.link, @"http://tracking.feedpress.it/link/980/4243452");
	XCTAssertEqualObjects(a.guid, @"50c628b3e4b07b56461546c5:50c658a6e4b0cc9aa9ce4405:57bcbe83e4fcb567fdffc020");
	XCTAssertEqual(a.datePublished, [NSDate dateWithTimeIntervalSince1970:1472163600]); // Thu, 25 Aug 2016 22:20:00 +0000
	
	[self measureBlock:^{
		[[xmlData getParser] parseSync:nil];
	}];
}


- (void)testEMarley {

	RSXMLData *xmlData = [self xmlFile:@"EMarley" extension:@"rss"];
	XCTAssertEqual(xmlData.parserClass, [RSRSSParser class]);
	
	NSError *error = nil;
	RSParsedFeed *parsedFeed = [[xmlData getParser] parseSync:&error];
	XCTAssertEqualObjects(parsedFeed.title, @"Stories by Liz Marley on Medium");
	XCTAssertEqualObjects(parsedFeed.subtitle, @"Stories by Liz Marley on Medium");
	XCTAssertEqualObjects(parsedFeed.link, @"https://medium.com/@emarley?source=rss-b4981c59ffa5------2");
	XCTAssertEqual(parsedFeed.articles.count, 10u);
	
	RSParsedArticle *a = parsedFeed.articles.firstObject;
	XCTAssertEqualObjects(a.title, @"UI Automation & screenshots");
	XCTAssertEqualObjects(a.link, @"https://medium.com/@emarley/ui-automation-screenshots-c44a41af38d1?source=rss-b4981c59ffa5------2");
	XCTAssertEqualObjects(a.guid, @"https://medium.com/p/c44a41af38d1");
	XCTAssertEqual(a.datePublished, [NSDate dateWithTimeIntervalSince1970:1462665210]); // Sat, 07 May 2016 23:53:30 GMT
	
	[self measureBlock:^{
		[[xmlData getParser] parseSync:nil];
	}];
}

- (void)testDaringFireball {
	
	RSXMLData *xmlData = [self xmlFile:@"DaringFireball" extension:@"atom"];
	XCTAssertEqual(xmlData.parserClass, [RSAtomParser class]);
	
	NSError *error = nil;
	RSParsedFeed *parsedFeed = [[xmlData getParser] parseSync:&error];
	XCTAssertEqualObjects(parsedFeed.title, @"Daring Fireball");
	XCTAssertEqualObjects(parsedFeed.subtitle, @"By John Gruber");
	XCTAssertEqualObjects(parsedFeed.link, @"http://daringfireball.net/");
	XCTAssertEqual(parsedFeed.articles.count, 47u);
	
	RSParsedArticle *a = parsedFeed.articles.firstObject;
	XCTAssertEqualObjects(a.title, @"Apple Product Event: Monday March 21");
	XCTAssertEqualObjects(a.link, @"http://recode.net/2016/02/27/remark-your-calendars-apples-product-event-will-week-of-march-21/");
	XCTAssertEqualObjects(a.guid, @"tag:daringfireball.net,2016:/linked//6.32173");
	XCTAssertEqual(a.datePublished, [NSDate dateWithTimeIntervalSince1970:1456610387]); // 2016-02-27T21:59:47Z
	
	[self measureBlock:^{
		[[xmlData getParser] parseSync:nil];
	}];
}


#pragma mark - Variety Test & Other


- (void)testCorrectParserSelection {
	RSXMLData *xmlData = [self xmlFile:@"OneFootTsunami" extension:@"atom"];
	RSFeedParser *rightParser = [RSFeedParser parserWithXMLData:xmlData];
	RSOPMLParser *wrongParser = [RSOPMLParser parserWithXMLData:xmlData];
	XCTAssertTrue([rightParser canParse]);
	XCTAssertFalse([wrongParser canParse]);
	NSError *error;
	[rightParser parseSync:&error];
	XCTAssertNil(error);
	[wrongParser parseSync:&error];
	XCTAssertNotNil(error);
	XCTAssertEqual(error.code, RSXMLErrorExpectingOPML);
	XCTAssertEqualObjects(error, RSXMLMakeErrorWrongParser(RSXMLErrorExpectingOPML, RSXMLErrorExpectingFeed, xmlData.url));
	XCTAssertEqualObjects(error.localizedDescription, @"Can't parse XML. OPML data expected, but RSS or Atom feed found.");
}

- (void)testDetermineParserClassPerformance {
	
	RSXMLData *xmlData = [self xmlFile:@"DaringFireball" extension:@"atom"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
	[self measureBlock:^{
		for (NSInteger i = 0; i < 100; i++) {
			[xmlData performSelector:@selector(determineParserClass)];
		}
	}];
#pragma clang diagnostic pop
}

- (void)testLowerAsciiCharacters {
	NSError *error = nil;
	RSXMLData *xmlData = [self xmlFile:@"lower-ascii" extension:@"rss"];
	RSXMLParser *parser = [xmlData getParser];
	RSParsedFeed *parsedFeed = [parser parseSync:&error];
	XCTAssertNotNil(error);
	XCTAssertEqual(parsedFeed.articles.count, 2);
	parser.dontStopOnLowerAsciiBytes = YES;
	parsedFeed = [parser parseSync:&error];
	XCTAssertNil(error);
	XCTAssertEqual(parsedFeed.articles.count, 5);
}

- (void)testBrokenXML {
	NSError *error = nil;
	RSXMLData *xmlData = [self xmlFile:@"broken" extension:@"rss"];
	[[xmlData getParser] parseSync:&error];
	XCTAssertNotNil(error);
	XCTAssertEqual(error.code, 76);
	XCTAssertEqualObjects(error.localizedDescription, @"Opening and ending tag mismatch: channel line 0 and rss");
}

- (void)testHttpSchemePrepending {
	NSError *error = nil;
	RSXMLData *xmlData = [self xmlFile:@"ccc-media" extension:@"rdf"];
	RSParsedFeed *parsedFeed = [[xmlData getParser] parseSync:&error];
	XCTAssertNil(error);
	XCTAssertEqualObjects(parsedFeed.link, @"http://media.ccc.de/");
}

- (void)testDownloadedFeeds {
	NSError *error = nil;
	int i = 0;
	while (true) {
		++i;
		RSXMLData *xmlData = [self xmlFile:[NSString stringWithFormat:@"feed_%d", i] extension:@"rss"];
		if (!xmlData) break;
		RSParsedFeed *parsedFeed = [[xmlData getParser] parseSync:&error];
		XCTAssertNil(error);
		XCTAssert(parsedFeed);
		XCTAssert(parsedFeed.title);
		XCTAssert(parsedFeed.link);
		XCTAssert(parsedFeed.articles.count > 0);
		//printf("\n\nparsing: %s\n%s\n", xmlData.urlString.UTF8String, parsedFeed.description.UTF8String);
	}
}

- (void)testDownloadedFeedsPerformance {
	[self measureBlock:^{
		[self testDownloadedFeeds];
	}];
}

- (void)testSingle {
	NSError *error = nil;
	RSXMLData *xmlData = [self xmlFile:@"feed_1" extension:@"rss"];
	RSParsedFeed *parsedFeed = [[xmlData getParser] parseSync:&error];
	printf("\n\nparsing: %s\n%s\n", xmlData.url.path.UTF8String, parsedFeed.description.UTF8String);
	XCTAssertNil(error);
}

@end
