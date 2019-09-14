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

#import "RSXMLData.h"
#import "RSXMLError.h"
// Parser classes
#import "RSRSSParser.h"
#import "RSAtomParser.h"
#import "RSOPMLParser.h"
#import "RSHTMLMetadataParser.h"

@implementation RSXMLData

static const NSUInteger minNumberOfBytesToSearch = 20;
static const NSUInteger numberOfCharactersToSearch = 4096;

- (instancetype)initWithData:(NSData *)data url:(NSURL *)url {
	self = [super init];
	if (self) {
		_data = data;
		_url = url;
		_parserError = nil;
		_parserClass = [self determineParserClass]; // will set error
		if (!_parserClass && _parserError)
			_data = nil;
	}
	return self;
}

/**
 Get location of @c str in data. May be inaccurate since UTF8 uses multi-byte characters.
 */
- (NSInteger)findCString:(const char*)str {
	char *foundStr = strnstr(_data.bytes, str, numberOfCharactersToSearch);
	if (foundStr == NULL) {
		return NSNotFound;
	}
	return foundStr - (char*)_data.bytes;
}

/**
 @return @c YES if any of the provided tags is found within the first 4096 bytes.
 */
- (BOOL)matchAny:(const char*[])tags count:(int)len {
	for (int i = 0; i < len; i++) {
		if ([self findCString:tags[i]] != NSNotFound) {
			return YES;
		}
	}
	return NO;
}

/**
 @return @c YES if all of the provided tags are found within the first 4096 bytes.
 */
- (BOOL)matchAll:(const char*[])tags count:(int)len {
	for (int i = 0; i < len; i++) {
		if ([self findCString:tags[i]] == NSNotFound) {
			return NO;
		}
	}
	return YES;
}

/**
 Do a fast @c strnstr() search on the @c char* data.
 All strings must match exactly and in the same order provided.
 */
- (BOOL)matchAllInCorrectOrder:(const char*[])tags count:(int)len {
	NSInteger oldPos = 0;
	for (int i = 0; i < len; i++) {
		NSInteger newPos = [self findCString:tags[i]];
		if (newPos == NSNotFound || newPos < oldPos) {
			return NO;
		}
		oldPos = newPos;
	}
	return YES;
}


#pragma mark - Determine XML Parser


/**
 Try to find the correct parser for the underlying data. Will return @c nil and @c error if couldn't be determined.

 @return Parser class: @c RSRSSParser, @c RSAtomParser, @c RSOPMLParser or @c RSHTMLMetadataParser.
 */
- (nullable Class)determineParserClass {
	// TODO: check for things like images and movies and return nil.
	if (!_data || _data.length < minNumberOfBytesToSearch) {
		// TODO: check size, type, etc.
		_parserError = RSXMLMakeError(RSXMLErrorNoData, _url);
		return nil;
	}
	if (NSNotFound == [self findCString:"<"]) {
		_parserError = RSXMLMakeError(RSXMLErrorMissingLeftCaret, _url);
		return nil;
	}
	if ([self matchAll:(const char*[]){"<rss", "<channel"} count:2]) { // RSS
		return [RSRSSParser class];
	}
	if ([self matchAll:(const char*[]){"<feed", "<entry"} count:2]) { // Atom
		return [RSAtomParser class];
	}
	if (NSNotFound != [self findCString:"<rdf:RDF"]) {
		return [RSRSSParser class]; //TODO: parse RDF feeds ... for now, use RSS parser.
	}
	if ([self matchAll:(const char*[]){"<opml", "<outline"} count:2]) {
		return [RSOPMLParser class];
	}
	if ([self matchAny:(const char*[]){"<html", "<HTML", "<body", "<meta", "doctype html", "DOCTYPE html", "DOCTYPE HTML"} count:7]) {
		// Won’t catch every single case, which is fine.
		return [RSHTMLMetadataParser class];
	}
	if ([self findCString:"<errors xmlns='http://schemas.google"] != NSNotFound) {
		_parserError = RSXMLMakeError(RSXMLErrorContainsXMLErrorsTag, _url);
		return nil;
	}
	// else: try slower NSString conversion and search case insensitive.
	return [self determineParserClassSafeAndSlow];
}

/**
 Create @c NSString object from @c .data and try to parse it as UTF8 and UTF16.
 Then search for each parser if the tags match (case insensitive) in the same order provided.
 */
- (nullable Class)determineParserClassSafeAndSlow {
	@autoreleasepool {
		NSString *s = [[NSString alloc] initWithBytesNoCopy:(void *)_data.bytes length:_data.length encoding:NSUTF8StringEncoding freeWhenDone:NO];
		if (!s) {
			s = [[NSString alloc] initWithBytesNoCopy:(void *)_data.bytes length:_data.length encoding:NSUnicodeStringEncoding freeWhenDone:NO];
		}
		if (!s) {
			_parserError = RSXMLMakeError(RSXMLErrorNoSuitableParser, _url);
			return nil;
		}

		NSRange wholeRange = NSMakeRange(0, s.length);
		for (Class parserClass in [self listOfParserClasses]) {
			NSArray<const NSString *> *tags = [parserClass parserRequireOrderedTags];
			
			NSUInteger oldPos = 0;
			for (NSString *tag in tags) {
				NSUInteger newPos = [s rangeOfString:tag options:NSCaseInsensitiveSearch range:wholeRange].location;
				if (newPos == NSNotFound || newPos < oldPos) {
					oldPos = NSNotFound;
					break;
				}
				oldPos = newPos;
			}
			if (oldPos != NSNotFound) {
				return parserClass;
			}
		}
	}
	// Try RSS anyway? libxml would return a parsing error
	_parserError = RSXMLMakeError(RSXMLErrorNoSuitableParser, _url);
	return nil;
}

/// @return List of parsers. @c RSRSSParser, @c RSAtomParser, @c RSOPMLParser.
- (NSArray *)listOfParserClasses {
	static NSArray *gParserClasses = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		gParserClasses = @[[RSRSSParser class], [RSAtomParser class], [RSOPMLParser class]];
	});
	return gParserClasses;
}


#pragma mark - Check Methods to Determine Parser Type


// docref in header
- (id)getParser {
	return [_parserClass parserWithXMLData:self];
}

// docref in header
- (BOOL)canParseData {
	return (_parserClass != nil && _parserError == nil);
}

@end
