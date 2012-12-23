//
//  CBPageLayer.m
//  ComicBook
//
//  Created by cbreak on 2012.12.23.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBPageLayer.h"

#import "CBFrame.h"

@implementation CBPageLayer

- (id)initWithFrame:(CBFrame*)frame_
{
	if (self = [super init])
	{
		frame = frame_;
		// TODO: Do this asynchronous for better interactivity
		self.contents = frame.image;
	}
	return self;
}

+ (CBPageLayer*)layerWithFrame:(CBFrame*)frame
{
	return [[CBPageLayer alloc] initWithFrame:frame];
}

@end
