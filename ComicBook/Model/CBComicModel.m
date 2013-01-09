//
//  CBComicModel.m
//  ComicBook
//
//  Created by cbreak on 2012.12.29.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBComicModel.h"

#import "CBFrameFactory.h"

@implementation CBComicModel

- (id)initWithURL:(NSURL*)url error:(NSError **)error
{
	if (self = [super init])
	{
		fileUrl = url;
		currentFrame = 0;
		frames = [[CBFrameFactory factory] framesFromURL:url error:error];
		if (!frames)
			self = nil;
	}
	return self;
}

+ (CBComicModel*)comicWithURL:(NSURL*)url error:(NSError **)error
{
	return [[self alloc] initWithURL:url error:error];
}

@synthesize fileUrl;

- (NSUInteger)frameCount
{
	return [frames count];
}

@synthesize currentFrame;

- (CBFrame*)frameAtIndex:(NSUInteger)idx
{
	if (idx < [frames count])
		return [frames objectAtIndex:idx];
	return nil;
}

@end
