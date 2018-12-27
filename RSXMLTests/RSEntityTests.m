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
@import RSXML;

@interface RSEntityTests : XCTestCase

@end

@implementation RSEntityTests

- (void)testInnerAmpersand {
	
	NSString *expectedResult = @"A&P";
	
	NSString *result = [@"A&amp;P" rs_stringByDecodingHTMLEntities];
	XCTAssertEqualObjects(result, expectedResult);
	
	result = [@"A&#038;P" rs_stringByDecodingHTMLEntities];
	XCTAssertEqualObjects(result, expectedResult);

	result = [@"A&#38;P" rs_stringByDecodingHTMLEntities];
	XCTAssertEqualObjects(result, expectedResult);

}

- (void)testSingleEntity {
	
	NSString *result = [@"&infin;" rs_stringByDecodingHTMLEntities];
	XCTAssertEqualObjects(result, @"∞");
	
	result = [@"&#038;" rs_stringByDecodingHTMLEntities];
	XCTAssertEqualObjects(result, @"&");
	
	result = [@"&rsquo;" rs_stringByDecodingHTMLEntities];
	XCTAssertEqualObjects(result, @"’");
}

- (void)testNotEntities {
	
	NSString *s = @"&&\t\nFoo & Bar &0; Baz & 1238 4948 More things &foobar;&";
	NSString *result = [s rs_stringByDecodingHTMLEntities];
	XCTAssertEqualObjects(result, s);
}

- (void)testURLs {
	
	NSString *urlString = @"http://www.nytimes.com/2015/09/05/us/at-west-point-annual-pillow-fight-becomes-weaponized.html?mwrsm=Email&#038;_r=1&#038;pagewanted=all";
	NSString *expectedResult = @"http://www.nytimes.com/2015/09/05/us/at-west-point-annual-pillow-fight-becomes-weaponized.html?mwrsm=Email&_r=1&pagewanted=all";
	
	NSString *result = [urlString rs_stringByDecodingHTMLEntities];
	XCTAssertEqualObjects(result, expectedResult);
}

- (void)testEntityPlusWhitespace {
	
	NSString *s = @"&infin; Permalink";
	NSString *expectedResult = @"∞ Permalink";
	
	NSString *result = [s rs_stringByDecodingHTMLEntities];
	XCTAssertEqualObjects(result, expectedResult);
}

- (void)testNonBreakingSpace {
	
	NSString *s = @"&nbsp;&#160; -- just some spaces";
	NSString *expectedResult = [NSString stringWithFormat:@"%C%C -- just some spaces", 160, 160];
	
	NSString *result = [s rs_stringByDecodingHTMLEntities];
	XCTAssertEqualObjects(result, expectedResult);
}

@end
