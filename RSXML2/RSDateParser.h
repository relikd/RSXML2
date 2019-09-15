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

@import Foundation;


/*Common web dates -- RFC 822 and 8601 -- are handled here:
 the formats you find in JSON and XML feeds.

 Any of these may return nil. They may also return garbage, given bad input.*/


NSDate *RSDateWithString(NSString *dateString);

/*If you're using a SAX parser, you have the bytes and don't need to convert to a string first.
 It's faster and uses less memory.
 (Assumes bytes are UTF-8 or ASCII. If you're using the libxml SAX parser, this will work.)*/

NSDate *RSDateWithBytes(const char *bytes, NSUInteger numberOfBytes);

