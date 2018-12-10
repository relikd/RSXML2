//
//  FeedParser.m
//  RSXML
//
//  Created by Brent Simmons on 1/4/15.
//  Copyright (c) 2015 Ranchero Software LLC. All rights reserved.
//

#import <libxml/xmlerror.h>
#import "RSFeedParser.h"
#import "FeedParser.h"
#import "RSXMLData.h"
#import "RSRSSParser.h"
#import "RSAtomParser.h"

static NSArray *parserClasses(void) {
	
	static NSArray *gParserClasses = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		gParserClasses = @[[RSRSSParser class], [RSAtomParser class]];
	});
	
	return gParserClasses;
}

static BOOL feedMayBeParseable(RSXMLData *xmlData) {
	
	/*Sanity checks.*/
	
	if (!xmlData.data) {
		return NO;
	}

	/*TODO: check size, type, etc.*/
	
	return YES;
}

static BOOL optimisticCanParseRSSData(const char *bytes, NSUInteger numberOfBytes);
static BOOL optimisticCanParseAtomData(const char *bytes, NSUInteger numberOfBytes);
static BOOL optimisticCanParseRDF(const char *bytes, NSUInteger numberOfBytes);
static BOOL dataIsProbablyHTML(const char *bytes, NSUInteger numberOfBytes);
static BOOL dataIsSomeWeirdException(const char *bytes, NSUInteger numberOfBytes);
static BOOL dataHasLeftCaret(const char *bytes, NSUInteger numberOfBytes);

static const NSUInteger maxNumberOfBytesToSearch = 4096;
static const NSUInteger minNumberOfBytesToSearch = 20;

typedef enum {
	RSXMLErrorNoData = 100,
	RSXMLErrorMissingLeftCaret,
	RSXMLErrorProbablyHTML,
	RSXMLErrorContainsXMLErrorsTag,
	RSXMLErrorNoSuitableParser
} RSXMLError;

static void setError(NSError **error, RSXMLError code) {
	if (!error) {
		return;
	}
	NSString *msg = @"";
	switch (code) { // switch statement will warn if an enum value is missing
		case RSXMLErrorNoData:
			msg = @"Couldn't parse feed. No data available.";
			break;
		case RSXMLErrorMissingLeftCaret:
			msg = @"Couldn't parse feed. Missing left caret character ('<').";
			break;
		case RSXMLErrorProbablyHTML:
			msg = @"Couldn't parse feed. Expecting XML data but found html data.";
			break;
		case RSXMLErrorContainsXMLErrorsTag:
			msg = @"Couldn't parse feed. XML contains 'errors' tag.";
			break;
		case RSXMLErrorNoSuitableParser:
			msg = @"Couldn't parse feed. No suitable parser found. XML document not well-formed.";
			break;
	}
	*error = [NSError errorWithDomain:kRSXMLParserErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: msg}];
}

static Class parserClassForXMLData(RSXMLData *xmlData, NSError **error) {
	
	if (!feedMayBeParseable(xmlData)) {
		setError(error, RSXMLErrorNoData);
		return nil;
	}
	
	// TODO: check for things like images and movies and return nil.
	
	const char *bytes = xmlData.data.bytes;
	NSUInteger numberOfBytes = xmlData.data.length;
	
	if (numberOfBytes > minNumberOfBytesToSearch) {
		
		if (numberOfBytes > maxNumberOfBytesToSearch) {
			numberOfBytes = maxNumberOfBytesToSearch;
		}

		if (!dataHasLeftCaret(bytes, numberOfBytes)) {
			setError(error, RSXMLErrorMissingLeftCaret);
			return nil;
		}
		if (optimisticCanParseRSSData(bytes, numberOfBytes)) {
			return [RSRSSParser class];
		}
		if (optimisticCanParseAtomData(bytes, numberOfBytes)) {
			return [RSAtomParser class];
		}
		if (optimisticCanParseRDF(bytes, numberOfBytes)) {
			return [RSRSSParser class]; //TODO: parse RDF feeds, using RSS parser so far ...
		}
		if (dataIsProbablyHTML(bytes, numberOfBytes)) {
			setError(error, RSXMLErrorProbablyHTML);
			return nil;
		}
		if (dataIsSomeWeirdException(bytes, numberOfBytes)) {
			setError(error, RSXMLErrorContainsXMLErrorsTag);
			return nil;
		}
	}
	
	for (Class parserClass in parserClasses()) {
		if ([parserClass canParseFeed:xmlData]) {
			return parserClass;
			//return [[parserClass alloc] initWithXMLData:xmlData]; // does not make sense to return instance
		}
	}
	// Try RSS anyway? libxml would return a parsing error
	setError(error, RSXMLErrorNoSuitableParser);
	return nil;
}

static id<FeedParser> parserForXMLData(RSXMLData *xmlData, NSError **error) {
	
	Class parserClass = parserClassForXMLData(xmlData, error);
	if (!parserClass) {
		return nil;
	}
	return [[parserClass alloc] initWithXMLData:xmlData];
}

static BOOL canParseXMLData(RSXMLData *xmlData) {
	
	return parserClassForXMLData(xmlData, nil) != nil;
}

static BOOL didFindString(const char *string, const char *bytes, NSUInteger numberOfBytes) {
	
	char *foundString = strnstr(bytes, string, numberOfBytes);
	return foundString != NULL;
}

static BOOL dataHasLeftCaret(const char *bytes, NSUInteger numberOfBytes) {

	return didFindString("<", bytes, numberOfBytes);
}

static BOOL dataIsProbablyHTML(const char *bytes, NSUInteger numberOfBytes) {
	
	// Won’t catch every single case, which is fine.
	
	if (didFindString("<html", bytes, numberOfBytes)) {
		return YES;
	}
	if (didFindString("<body", bytes, numberOfBytes)) {
		return YES;
	}
	if (didFindString("doctype html", bytes, numberOfBytes)) {
		return YES;
	}
	if (didFindString("DOCTYPE html", bytes, numberOfBytes)) {
		return YES;
	}
	if (didFindString("DOCTYPE HTML", bytes, numberOfBytes)) {
		return YES;
	}
	if (didFindString("<meta", bytes, numberOfBytes)) {
		return YES;
	}
	if (didFindString("<HTML", bytes, numberOfBytes)) {
		return YES;
	}
	
	return NO;
}

static BOOL dataIsSomeWeirdException(const char *bytes, NSUInteger numberOfBytes) {

	if (didFindString("<errors xmlns='http://schemas.google", bytes, numberOfBytes)) {
		return YES;
	}

	return NO;
}

static BOOL optimisticCanParseRDF(const char *bytes, NSUInteger numberOfBytes) {
	
	return didFindString("<rdf:RDF", bytes, numberOfBytes);
}

static BOOL optimisticCanParseRSSData(const char *bytes, NSUInteger numberOfBytes) {
	
	if (!didFindString("<rss", bytes, numberOfBytes)) {
		return NO;
	}
	return didFindString("<channel", bytes, numberOfBytes);
}

static BOOL optimisticCanParseAtomData(const char *bytes, NSUInteger numberOfBytes) {
	
	return didFindString("<feed", bytes, numberOfBytes);
}

static void callCallback(RSParsedFeedBlock callback, RSParsedFeed *parsedFeed, NSError *error) {
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		@autoreleasepool {
			if (callback) {
				callback(parsedFeed, error);
			}
		}
	});
}


#pragma mark - API

BOOL RSCanParseFeed(RSXMLData *xmlData) {

	return canParseXMLData(xmlData);
}

void RSParseFeed(RSXMLData *xmlData, RSParsedFeedBlock callback) {

	dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{

		NSError *error = nil;
		RSParsedFeed *parsedFeed = RSParseFeedSync(xmlData, &error);
		callCallback(callback, parsedFeed, error);
	});
}

RSParsedFeed *RSParseFeedSync(RSXMLData *xmlData, NSError **error) {

	xmlResetLastError();
	id<FeedParser> parser = parserForXMLData(xmlData, error);
	if (error && *error) {
		//printf("ERROR in parserForXMLData(): %s\n", [[*error localizedDescription] UTF8String]);
		return nil;
	}
	RSParsedFeed *parsedResult = [parser parseFeed];
	
	xmlErrorPtr err = xmlGetLastError();
	if (err && error) {
		int errCode = err->code;
		char * msg = err->message;
		//if (err->level == XML_ERR_FATAL)
		NSString *errMsg = [[NSString stringWithFormat:@"%s", msg] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		*error = [NSError errorWithDomain:kLIBXMLParserErrorDomain code:errCode userInfo:@{NSLocalizedDescriptionKey: errMsg}];
		//printf("ERROR in [parseFeed] (%d): %s\n", err->level, [[*error localizedDescription] UTF8String]);
		xmlResetLastError();
	}
	return parsedResult;
}

