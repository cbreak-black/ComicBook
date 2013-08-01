//
//  CBPageLayer.m
//  ComicBook
//
//  Created by cbreak on 2012.12.23.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBPageLayer.h"

// Single Page Aspect limit (Standard DIN A4 Paper has an aspect of 0.71)
static const CGFloat kCBPageAspectMin = 0.5;

@implementation CBPageLayer

- (id)init
{
	if (self = [super init])
	{
		aspect = CGFLOAT_MAX;
		width = 1.0;
		alignment = kCBPageUnaligned;
		isLaidOut = NO;
		self.shadowOpacity = 0.25;
		self.shadowRadius = 0.025;
		self.minificationFilter = kCAFilterTrilinear;
		self.magnificationFilter = kCAFilterLinear; // Default
	}
	return self;
}

- (void)setImage:(NSImage*)image forFrame:(CBFrame*)comicFrame_
{
	@synchronized (self)
	{
		alignment = kCBPageUnaligned;
		isLaidOut = NO;
		comicFrame = comicFrame_;
		if (image)
		{
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
		[self calculateBounds];
	}
}

@synthesize comicFrame;
@synthesize aspect;

- (void)calculateBounds
{
	if (alignment != kCBPageDouble && aspect < kCBPageAspectMin)
	{
		// Prevent abnormally tall single pages
		CGFloat maxHeight = width/kCBPageAspectMin;
		self.bounds = CGRectMake(0, 0, maxHeight*aspect, maxHeight);
	}
	else
	{
		self.bounds = CGRectMake(0, 0, width, width/aspect);
	}
}

- (void)setWidth:(CGFloat)width_
{
	@synchronized (self)
	{
		width = width_;
		[self calculateBounds];
	}
}

- (CGFloat)width
{
	@synchronized (self)
	{
		return width;
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
				break;
			case kCBPageRight:
				self.anchorPoint = CGPointMake(0.0, 1.0);
				break;
			case kCBPageDouble:
				self.anchorPoint = CGPointMake(0.5, 1.0);
				break;
			default:
				return;
		}
		alignment = alignment_;
		[self calculateBounds];
	}
}

- (CBPageAlignment)alignment
{
	return alignment;
}

- (CGRect)effectiveBounds
{
	CGPoint anchor = self.anchorPoint;
	CGPoint position = self.position;
	CGRect bounds =  CGRectOffset(self.bounds, position.x, position.y);
	return CGRectOffset(bounds,
						-bounds.size.width*anchor.x,
						-bounds.size.height*anchor.y);
}

- (BOOL)isDoublePage
{
	if (aspect != CGFLOAT_MAX)
		return aspect > kCBPageDoubleThreshold;
	return NO;
}

@synthesize isLaidOut;

- (BOOL)isValid
{
	return comicFrame != nil;
}

@end
