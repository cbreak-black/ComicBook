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

- (id)init
{
	if (self = [super init])
	{
	}
	return self;
}

- (id)initWithComicBookFrame:(CBFrame*)frame
{
	if (self = [super init])
	{
		comicBookFrame = frame;
		self.contents = comicBookFrame.image;
	}
	return self;
}

- (void)setComicBookFrame:(CBFrame *)comicBookFrame_
{
	comicBookFrame = comicBookFrame_;
	self.contents = comicBookFrame.image;
}

@synthesize comicBookFrame;

@end
