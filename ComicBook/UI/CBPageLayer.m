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
		aspect = CGFLOAT_MAX;
		alignment = kCBPageUnaligned;
		isLaidOut = NO;
	}
	return self;
}

- (id)initWithComicBookFrame:(CBFrame*)frame
{
	if (self = [self init])
	{
		[self setComicBookFrame:frame];
	}
	return self;
}

- (void)setComicBookFrame:(CBFrame *)comicBookFrame_
{
	@synchronized (self)
	{
		comicBookFrame = comicBookFrame_;
		alignment = kCBPageUnaligned;
		isLaidOut = NO;
		if (comicBookFrame)
		{
			NSImage * image = comicBookFrame.image;
			NSSize imageSize = [image size];
			if (imageSize.width > 0 && imageSize.height > 0)
				aspect = (CGFloat)imageSize.width/(CGFloat)imageSize.height;
			else
				aspect = CGFLOAT_MAX;
			self.contents = image;
		}
		else
		{
			aspect = CGFLOAT_MAX;
			self.contents = nil;
		}
		self.bounds = CGRectMake(0, 0, 0, 0);
	}
}

@synthesize comicBookFrame;

@synthesize aspect;

- (void)setPosition:(CGPoint)position withAlignment:(CBPageAlignment)alignment_
{
	@synchronized (self)
	{
		[self setAlignment:alignment_];
		[self setPosition:position];
	}
}

- (void)setPosition:(CGPoint)position
{
	@synchronized (self)
	{
		[super setPosition:position];
		isLaidOut = YES;
	}
}

- (void)setAlignment:(CBPageAlignment)alignment_
{
	@synchronized (self)
	{
		switch (alignment_)
		{
			case kCBPageLeft:
				self.anchorPoint = CGPointMake(1.0, 1.0);
				self.bounds = CGRectMake(0, 0, 1.0, 1.0/aspect);
				break;
			case kCBPageRight:
				self.anchorPoint = CGPointMake(0.0, 1.0);
				self.bounds = CGRectMake(0, 0, 1.0, 1.0/aspect);
				break;
			case kCBPageDouble:
				self.anchorPoint = CGPointMake(0.5, 1.0);
				self.bounds = CGRectMake(0, 0, 2.0, 2.0/aspect);
				break;
			default:
				return;
		}
		alignment = alignment_;
	}
}

- (CBPageAlignment)alignment
{
	return alignment;
}

- (BOOL)isDoublePage
{
	return aspect > kCBPageDoubleThreshold;
}

@synthesize isLaidOut;

@end