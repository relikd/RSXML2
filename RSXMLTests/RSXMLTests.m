//
//  RSXMLTests.m
//  RSXMLTests
//
//  Created by Brent Simmons on 7/12/15.
//  Copyright © 2015 Ranchero Software, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
@import RSXML;

@interface RSXMLTests : XCTestCase

@end

@implementation RSXMLTests

+ (RSXMLData *)oftData {

	static RSXMLData *xmlData = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *s = [[NSBundle bundleForClass:[self class]] pathForResource:@"OneFootTsunami" ofType:@"atom" inDirectory:@"Resources"];
		NSData *d = [[NSData alloc] initWithContentsOfFile:s];
		xmlData = [[RSXMLData alloc] initWithData:d urlString:@"http://onefoottsunami.com/"];
	});

	return xmlData;
}


+ (RSXMLData *)scriptingNewsData {

	static RSXMLData *xmlData = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *s = [[NSBundle bundleForClass:[self class]] pathForResource:@"scriptingNews" ofType:@"rss" inDirectory:@"Resources"];
		NSData *d = [[NSData alloc] initWithContentsOfFile:s];
		xmlData = [[RSXMLData alloc] initWithData:d urlString:@"http://scripting.com/"];
	});

	return xmlData;
}


+ (RSXMLData *)mantonData {

	static RSXMLData *xmlData = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *s = [[NSBundle bundleForClass:[self class]] pathForResource:@"manton" ofType:@"rss" inDirectory:@"Resources"];
		NSData *d = [[NSData alloc] initWithContentsOfFile:s];
		xmlData = [[RSXMLData alloc] initWithData:d urlString:@"http://manton.org/"];
	});

	return xmlData;
}


+ (RSXMLData *)daringFireballData {

	static RSXMLData *xmlData = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *s = [[NSBundle bundleForClass:[self class]] pathForResource:@"DaringFireball" ofType:@"rss" inDirectory:@"Resources"];
		NSData *d = [[NSData alloc] initWithContentsOfFile:s];
		xmlData = [[RSXMLData alloc] initWithData:d urlString:@"http://daringfireball.net/"];
	});

	return xmlData;
}


+ (RSXMLData *)katieFloydData {

	static RSXMLData *xmlData = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *s = [[NSBundle bundleForClass:[self class]] pathForResource:@"KatieFloyd" ofType:@"rss" inDirectory:@"Resources"];
		NSData *d = [[NSData alloc] initWithContentsOfFile:s];
		xmlData = [[RSXMLData alloc] initWithData:d urlString:@"http://katiefloyd.com/"];
	});

	return xmlData;
}


+ (RSXMLData *)eMarleyData {

	static RSXMLData *xmlData = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *s = [[NSBundle bundleForClass:[self class]] pathForResource:@"EMarley" ofType:@"rss" inDirectory:@"Resources"];
		NSData *d = [[NSData alloc] initWithContentsOfFile:s];
		xmlData = [[RSXMLData alloc] initWithData:d urlString:@"https://medium.com/@emarley"];
	});

	return xmlData;
}


- (void)testOneFootTsunami {

	NSError *error = nil;
	RSXMLData *xmlData = [[self class] oftData];
	RSParsedFeed *parsedFeed = RSParseFeedSync(xmlData, &error);
	NSLog(@"parsedFeed: %@", parsedFeed);
}


- (void)testOFTPerformance {

	RSXMLData *xmlData = [[self class] oftData];

	[self measureBlock:^{
		NSError *error = nil;
		RSParseFeedSync(xmlData, &error);
	}];
}


- (void)testScriptingNews {

	NSError *error = nil;
	RSXMLData *xmlData = [[self class] scriptingNewsData];
	RSParsedFeed *parsedFeed = RSParseFeedSync(xmlData, &error);
	NSLog(@"parsedFeed: %@", parsedFeed);
}


- (void)testManton {

	NSError *error = nil;
	RSXMLData *xmlData = [[self class] mantonData];
	RSParsedFeed *parsedFeed = RSParseFeedSync(xmlData, &error);
	NSLog(@"parsedFeed: %@", parsedFeed);
}


- (void)testKatieFloyd {

	NSError *error = nil;
	RSXMLData *xmlData = [[self class] katieFloydData];
	RSParsedFeed *parsedFeed = RSParseFeedSync(xmlData, &error);
	XCTAssertEqualObjects(parsedFeed.title, @"Katie Floyd");
}


- (void)testEMarley {

	NSError *error = nil;
	RSXMLData *xmlData = [[self class] eMarleyData];
	RSParsedFeed *parsedFeed = RSParseFeedSync(xmlData, &error);
	XCTAssertEqualObjects(parsedFeed.title, @"Stories by Liz Marley on Medium");
	XCTAssertEqual(parsedFeed.articles.count, 10u);
}


- (void)testScriptingNewsPerformance {

	RSXMLData *xmlData = [[self class] scriptingNewsData];

	[self measureBlock:^{
		NSError *error = nil;
		RSParseFeedSync(xmlData, &error);
	}];

}


- (void)testMantonPerformance {

	RSXMLData *xmlData = [[self class] mantonData];

	[self measureBlock:^{
		NSError *error = nil;
		RSParseFeedSync(xmlData, &error);
	}];

}


- (void)testDaringFireballPerformance {

	RSXMLData *xmlData = [[self class] daringFireballData];

	[self measureBlock:^{
		NSError *error = nil;
		RSParseFeedSync(xmlData, &error);
	}];
}


- (void)testCanParseFeedPerformance {
	
	RSXMLData *xmlData = [[self class] daringFireballData];
	// 0.379
	[self measureBlock:^{
		for (NSInteger i = 0; i < 100; i++) {
			RSCanParseFeed(xmlData);
		}
	}];
}

- (void)testDownloadedFeeds {
	NSError *error = nil;
	int i = 0;
	while (true) {
		++i;
		NSString *pth = [NSString stringWithFormat:@"feed_%d", i];
		NSString *s = [[NSBundle bundleForClass:[self class]] pathForResource:pth ofType:@"rss" inDirectory:@"Resources"];
		if (s == nil) {
			break;
		}
		NSData *d = [[NSData alloc] initWithContentsOfFile:s];
		RSXMLData *xmlData = [[RSXMLData alloc] initWithData:d urlString:pth];
		RSParsedFeed *parsedFeed = RSParseFeedSync(xmlData, &error);
		printf("\n\nparsing: %s\n%s\n", pth.UTF8String, parsedFeed.description.UTF8String);
		XCTAssertNil(error);
	}
}

- (void)testSingle {
	NSError *error = nil;
	NSString *filename = @"feed_1";
	NSString *s = [[NSBundle bundleForClass:[self class]] pathForResource:filename ofType:@"rss" inDirectory:@"Resources"];
	NSData *d = [[NSData alloc] initWithContentsOfFile:s];
	RSXMLData *xmlData = [[RSXMLData alloc] initWithData:d urlString:@"single-feed"];
	RSParsedFeed *parsedFeed = RSParseFeedSync(xmlData, &error);
	printf("\n\nparsing: %s\n%s\n", filename.UTF8String, parsedFeed.description.UTF8String);
	XCTAssertNil(error);
}

@end
