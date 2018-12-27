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

#import "RSXMLError.h"

const NSErrorDomain kLIBXMLParserErrorDomain = @"LIBXMLParserErrorDomain";
const NSErrorDomain kRSXMLParserErrorDomain = @"RSXMLParserErrorDomain";

const char * parserDescriptionForError(RSXMLError code);
const char * parserDescriptionForError(RSXMLError code) {
	switch (code) {
		case RSXMLErrorExpectingHTML: return "HTML data";
		case RSXMLErrorExpectingOPML: return "OPML data";
		case RSXMLErrorExpectingFeed: return "RSS or Atom feed";
		default: return "Unknown format";
	}
}

NSString * getErrorMessageForRSXMLError(RSXMLError code, RSXMLError expected);
NSString * getErrorMessageForRSXMLError(RSXMLError code, RSXMLError expected) {
	switch (code) { // switch statement will warn if an enum value is missing
		case RSXMLErrorNoData:
			return @"Can't parse data. Empty data.";
		case RSXMLErrorInputEncoding:
			return @"Can't parse data. Input encoding cannot be converted to UTF-8 / UTF-16.";
		case RSXMLErrorMissingLeftCaret:
			return @"Can't parse XML. Missing left caret character ('<').";
		case RSXMLErrorContainsXMLErrorsTag:
			return @"Can't parse XML. XML contains 'errors' tag.";
		case RSXMLErrorNoSuitableParser:
			return @"Can't parse XML. No suitable parser found. Document not well-formed?";
		case RSXMLErrorExpectingHTML:
		case RSXMLErrorExpectingOPML:
		case RSXMLErrorExpectingFeed:
			return [NSString stringWithFormat:@"Can't parse XML. %s expected, but %s found.",
					parserDescriptionForError(code), parserDescriptionForError(expected)];
	}
}

NSError * RSXMLMakeError(RSXMLError code) {
	return RSXMLMakeErrorWrongParser(code, RSXMLErrorNoData);
}

NSError * RSXMLMakeErrorWrongParser(RSXMLError code, RSXMLError expected) {
	return [NSError errorWithDomain:kRSXMLParserErrorDomain code:code
						   userInfo:@{NSLocalizedDescriptionKey: getErrorMessageForRSXMLError(code, expected)}];
}

NSError * RSXMLMakeErrorFromLIBXMLError(xmlErrorPtr err) {
	if (err && err->level == XML_ERR_FATAL) {
		int errCode = err->code;
		char * msg = err->message;
		//if (err->level == XML_ERR_FATAL)
		NSString *errMsg = [[NSString stringWithFormat:@"%s", msg] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		return [NSError errorWithDomain:kLIBXMLParserErrorDomain code:errCode userInfo:@{NSLocalizedDescriptionKey: errMsg}];
	}
	return nil;
}
