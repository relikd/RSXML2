//
//  RSOPMLParser.h
//  RSXML
//
//  Created by Brent Simmons on 7/12/15.
//  Copyright © 2015 Ranchero Software, LLC. All rights reserved.
//

@import Foundation;


@class RSXMLData;
@class RSOPMLItem;


typedef void (^RSParsedOPMLBlock)(RSOPMLItem *opmlDocument, NSError *error);

void RSParseOPML(RSXMLData *xmlData, RSParsedOPMLBlock callback); //async; calls back on main thread.


@interface RSOPMLParser: NSObject

- (instancetype)initWithXMLData:(RSXMLData *)xmlData;

@property (nonatomic, readonly) RSOPMLItem *opmlDocument;
@property (nonatomic, readonly) NSError *error;

@end

