//
//  CBFrame.m
//  ComicBook
//
//  Created by cbreak on 2012.12.22.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBFrame.h"

@implementation CBFrame

- (id)init
{
	if (self = [super init])
	{
	}
	return self;
}

- (NSString*)path
{
	return @"";
}

- (NSImage*)image
{
	// TODO: Return placeholder image
	return nil;
}

+ (id<CBFrameLoader>)loader
{
	return nil;
}

@end
