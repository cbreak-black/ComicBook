//
//  CBFrameDataSource.m
//  ComicBook
//
//  Created by cbreak on 2013.03.15.
//  Copyright (c) 2013 the-color-black.net. All rights reserved.
//

#import "CBFrameDataSource.h"

@implementation CBFrameStoredDataSource

- (id)initWithData:(NSData*)data withPath:(NSString*)path
{
	if (self = [super init])
	{
		frameData = data;
		framePath = path;
	}
	return self;
}

@synthesize frameData;
@synthesize framePath;

@end
