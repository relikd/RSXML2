
#import "RSXMLError.h"

NSErrorDomain kLIBXMLParserErrorDomain = @"LIBXMLParserErrorDomain";
NSErrorDomain kRSXMLParserErrorDomain = @"RSXMLParserErrorDomain";

NSString * getErrorMessageForRSXMLError(RSXMLError code, id paramA);
NSString * getErrorMessageForRSXMLError(RSXMLError code, id paramA) {
	switch (code) { // switch statement will warn if an enum value is missing
		case RSXMLErrorNoData:
			return @"Couldn't parse feed. No data available.";
		case RSXMLErrorMissingLeftCaret:
			return @"Couldn't parse feed. Missing left caret character ('<').";
		case RSXMLErrorProbablyHTML:
			return @"Couldn't parse feed. Expecting XML data but found html data.";
		case RSXMLErrorContainsXMLErrorsTag:
			return @"Couldn't parse feed. XML contains 'errors' tag.";
		case RSXMLErrorNoSuitableParser:
			return @"Couldn't parse feed. No suitable parser found. XML document not well-formed.";
		case RSXMLErrorFileNotOPML:
			if (paramA) {
				return [NSString stringWithFormat:@"The file ‘%@’ can't be parsed because it's not an OPML file.", paramA];
			}
			return @"The file can't be parsed because it's not an OPML file.";
	}
}

void RSXMLSetError(NSError **error, RSXMLError code, NSString *filename) {
	if (error) {
		*error = RSXMLMakeError(code, filename);
	}
}

NSError * RSXMLMakeError(RSXMLError code, NSString *filename) {
	return [NSError errorWithDomain:kRSXMLParserErrorDomain code:code
						   userInfo:@{NSLocalizedDescriptionKey: getErrorMessageForRSXMLError(code, nil)}];
}

NSError * RSXMLMakeErrorFromLIBXMLError(xmlErrorPtr err) {
	if (err) {
		int errCode = err->code;
		char * msg = err->message;
		//if (err->level == XML_ERR_FATAL)
		NSString *errMsg = [[NSString stringWithFormat:@"%s", msg] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		return [NSError errorWithDomain:kLIBXMLParserErrorDomain code:errCode userInfo:@{NSLocalizedDescriptionKey: errMsg}];
	}
	return nil;
}
