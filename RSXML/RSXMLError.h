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

@import Foundation;

extern NSErrorDomain const kLIBXMLParserErrorDomain;
extern NSErrorDomain const kRSXMLParserErrorDomain;

/// Error codes for RSXML error domain @c (kRSXMLParserErrorDomain)
typedef NS_ERROR_ENUM(kRSXMLParserErrorDomain, RSXMLError) {
	/// Error codes
	// 1xx: general xml parsing error
	RSXMLErrorNoData               = 110, // input length is less than 20 characters
	RSXMLErrorInputEncoding        = 111, // input is not decodable with UTF8 or UTF16 encoding
	RSXMLErrorMissingLeftCaret     = 120, // input does not contain any '<' character
	RSXMLErrorContainsXMLErrorsTag = 130, // input contains: "<errors xmlns='http://schemas.google"
	RSXMLErrorNoSuitableParser     = 140, // none of the provided parsers can read the data
	// 2xx: xml content <-> parser, mismatch
	RSXMLErrorExpectingFeed        = 210,
	RSXMLErrorExpectingHTML        = 220,
	RSXMLErrorExpectingOPML        = 230
};

NSError * RSXMLMakeError(RSXMLError code);
NSError * RSXMLMakeErrorWrongParser(RSXMLError expected, RSXMLError other);
