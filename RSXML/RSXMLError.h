
@import Foundation;
#import <libxml/xmlerror.h>

extern NSErrorDomain kLIBXMLParserErrorDomain;
extern NSErrorDomain kRSXMLParserErrorDomain;

/// Error codes for RSXML error domain @c (kRSXMLParserErrorDomain)
typedef NS_ENUM(NSInteger, RSXMLError) {
	/// Error codes
	RSXMLErrorNoData               = 100,
	RSXMLErrorMissingLeftCaret     = 110,
	RSXMLErrorProbablyHTML         = 120,
	RSXMLErrorContainsXMLErrorsTag = 130,
	RSXMLErrorNoSuitableParser     = 140,
	RSXMLErrorFileNotOPML          = 1024 // original value
};

void RSXMLSetError(NSError **error, RSXMLError code, NSString *filename);
NSError * RSXMLMakeError(RSXMLError code, NSString *filename);
NSError * RSXMLMakeErrorFromLIBXMLError(xmlErrorPtr err);
