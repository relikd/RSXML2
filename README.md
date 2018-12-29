# RSXML

This is utility code for parsing XML and HTML using libXML2’s SAX parser. It does not depend on any other third-party frameworks and builds two targets: one for Mac, one for iOS.

**Note:** This is an actively maintained fork of the [RSXML library by Brent Simmons](https://github.com/brentsimmons/RSXML). The original library seems to be inactive in favor of the new version [RSParser](https://github.com/brentsimmons/RSParser) which is written with Swift support in mind. If you prefer Swift you should go ahead and work with that project. However, the reason for this fork is to keep a version alive which is Objective-C only.



### Why use libXML2’s SAX API?

Brent Simmons put much value on low memory footprint and fast parsing. With his own words: "RSXML was written to avoid allocating Objective-C objects except when absolutely needed. You'll note use of things like `memcmp` and `strncmp`". This promise will not be broken in future development.



### Refactoring v.2.0

The refactoring that led to version 2.0 changed many things. With nearly all files touched, I would say roughly 80% of the code was updated. The parser architecture was rewritten and every parser is now a subclass of `RSXMLParser`. The parsing interface uses generic return types and some of the returned documents have changed as well.

In general, the performance did not change but if so only to get slightly better. However, the performance of the HTML metadata parser improved by 80% – 90% (by canceling the parse after the head tag). At the same time, heap allocations dropped to 50% – 30% for the test cases (same reason).

In the previous version, the test case for parsing a non-opml file (with `RSOPMLParser`) took 13 seconds, whereas now, the parser cancels after a few milliseconds.



## Usage

```
RSXMLData *xmlData = [[RSXMLData alloc] initWithData:d urlString:@"https://www.example.org"];
// TODO: check xmlData.parserError
RSFeedParser *parser = [RSFeedParser parserWithXMLData:xmlData];
// TODO: check [parser canParse]
// TODO: alternatively check error after parseSync:
NSError *parseError;
RSParsedFeed *document = [parser parseSync:&parseError];
```

`RSXMLData` will return an error in `.parserError` if the provided data is not in XML format (see `RSXMLError` for possible reasons). The other point of failure is after initializing a parser with the `RSXMLData`. This will set an error if the parser does not match the underlying data (e.g., if you try to parse an `.opml` file with an Atom or RSS parser).

If you don't care about the parser used to decode the data, `[xmlData getParser]` will return the most suitable parser. You can use that parser right away to call `parseSync:`. Anyway, you can also parse the XML file asynchronously with `parseAsync:`.

```
[[xmlData getParser] parseAsync:^(RSParsedFeed *parsedDocument, NSError *error) {
	// process feed items ...
}];
```



### Available parsers

This library includes parsers for RSS, Atom, OPML, and HTML metadata. The latter will return links to feed URLs, icon files, or generally all anchor tags linking to whatever. Use `RSFeedParser` to parse a feed regardless of type (Atom: `RSAtomParser`, RSS: `RSRSSParser`). To parse `.opml` files use `RSOPMLParser`, and for `.html` files there are two available `RSHTMLMetadataParser` (icons and feed links) and `RSHTMLLinkParser` (all anchor tags).

Depending on the parser the return value of `parseSync`/`parseAsync` is: `RSParsedFeed`, `RSOPMLItem`, `RSHTMLMetadata`, or `RSHTMLMetadataAnchor`.

You can define the parser type by declaring it like this: `RSXMLData<RSFeedParser*> xmlData`. That won't force the selection of the parser, though. But `[xmlData getParser]` will return the correct type; which in turn will return the appropriate document type (same as using a specific parser in the first place).



### Extras

`RSDateParser` makes it easy to parse dates from various formats found in different feed types.

`NSString+RSXML` decodes HTML entities.

Also note: there are some unit tests.

