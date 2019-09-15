//
//  MIT License (MIT)
//
//  Copyright (c) 2016 Brent Simmons
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
@import RSXML2;

@interface RSDateParserTests : XCTestCase

@end

@implementation RSDateParserTests

static NSDate *dateWithValues(NSInteger year, NSInteger month, NSInteger day, NSInteger hour, NSInteger minute, NSInteger second) {
	
	NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
	dateComponents.calendar = NSCalendar.currentCalendar;
	dateComponents.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
	[dateComponents setValue:year forComponent:NSCalendarUnitYear];
	[dateComponents setValue:month forComponent:NSCalendarUnitMonth];
	[dateComponents setValue:day forComponent:NSCalendarUnitDay];
	[dateComponents setValue:hour forComponent:NSCalendarUnitHour];
	[dateComponents setValue:minute forComponent:NSCalendarUnitMinute];
	[dateComponents setValue:second forComponent:NSCalendarUnitSecond];
	
	return dateComponents.date;
}

- (void)testDateWithString {
	
	NSDate *expectedDateResult = dateWithValues(2010, 5, 28, 21, 3, 38);
	XCTAssertNotNil(expectedDateResult);

	NSDate *d = RSDateWithString(@"Fri, 28 May 2010 21:03:38 +0000");
	XCTAssertEqualObjects(d, expectedDateResult);

	d = RSDateWithString(@"Fri, 28 May 2010 21:03:38 +00:00");
	XCTAssertEqualObjects(d, expectedDateResult);

	d = RSDateWithString(@"Fri, 28 May 2010 21:03:38 -00:00");
	XCTAssertEqualObjects(d, expectedDateResult);

	d = RSDateWithString(@"Fri, 28 May 2010 21:03:38 -0000");
	XCTAssertEqualObjects(d, expectedDateResult);

	d = RSDateWithString(@"Fri, 28 May 2010 21:03:38 GMT");
	XCTAssertEqualObjects(d, expectedDateResult);

	d = RSDateWithString(@"2010-05-28T21:03:38+00:00");
	XCTAssertEqualObjects(d, expectedDateResult);
	
	d = RSDateWithString(@"2010-05-28T21:03:38+0000");
	XCTAssertEqualObjects(d, expectedDateResult);

	d = RSDateWithString(@"2010-05-28T21:03:38-0000");
	XCTAssertEqualObjects(d, expectedDateResult);

	d = RSDateWithString(@"2010-05-28T21:03:38-00:00");
	XCTAssertEqualObjects(d, expectedDateResult);

	d = RSDateWithString(@"2010-05-28T21:03:38Z");
	XCTAssertEqualObjects(d, expectedDateResult);

	expectedDateResult = dateWithValues(2010, 7, 13, 17, 6, 40);
	d = RSDateWithString(@"2010-07-13T17:06:40+00:00");
	XCTAssertEqualObjects(d, expectedDateResult);

	expectedDateResult = dateWithValues(2010, 4, 30, 12, 0, 0);
	d = RSDateWithString(@"30 Apr 2010 5:00 PDT");
	XCTAssertEqualObjects(d, expectedDateResult);

	expectedDateResult = dateWithValues(2010, 5, 21, 21, 22, 53);
	d = RSDateWithString(@"21 May 2010 21:22:53 GMT");
	XCTAssertEqualObjects(d, expectedDateResult);
	
	expectedDateResult = dateWithValues(2010, 6, 9, 5, 0, 0);
	d = RSDateWithString(@"Wed, 09 Jun 2010 00:00 EST");
	XCTAssertEqualObjects(d, expectedDateResult);

	expectedDateResult = dateWithValues(2010, 6, 23, 3, 43, 50);
	d = RSDateWithString(@"Wed, 23 Jun 2010 03:43:50 Z");
	XCTAssertEqualObjects(d, expectedDateResult);

	expectedDateResult = dateWithValues(2010, 6, 22, 3, 57, 49);
	d = RSDateWithString(@"2010-06-22T03:57:49+00:00");
	XCTAssertEqualObjects(d, expectedDateResult);

	expectedDateResult = dateWithValues(2010, 11, 17, 13, 40, 07);
	d = RSDateWithString(@"2010-11-17T08:40:07-05:00");
	XCTAssertEqualObjects(d, expectedDateResult);
}


@end
