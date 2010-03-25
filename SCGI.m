//
//  scgi.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 29.12.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SCGI.h"

NSData* SCGIcreateRequest (NSString * input)
{
	//	String res = "CONTENT_LENGTH\0" + (body != null ? body.length() : 0)
	//	+ "\0SCGI\0" + "1\0";
	//	if (header != null) {
	//		for (Map.Entry<String, String> entry : header.entrySet())
	//			res += entry.getKey() + '\0' + entry.getValue() + '\0';
	//	}
	//	String size = new Integer(res.getBytes().length) + ":";
	//	res += "," + body;
	//	return size + res;
	
	NSString* header = [[NSString alloc] initWithFormat:@"CONTENT_LENGTH\0%d\0SCGI\01\0",(input == NULL ?0 : [input length])];
	
	NSString* data = [[NSString alloc] initWithFormat:@"%i:%@,%@", [header length], header, input];
	
	NSData* result = [data dataUsingEncoding: NSUTF8StringEncoding];
	
	[header release];
	
	[data release];
	
	return result;
}