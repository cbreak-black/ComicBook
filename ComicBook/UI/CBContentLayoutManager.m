//
//  CBContentLayoutManager.m
//  ComicBook
//
//  Created by cbreak on 2013.01.09.
//  Copyright (c) 2013 the-color-black.net. All rights reserved.
//

#import "CBContentLayoutManager.h"

@implementation CBContentLayoutManager

- (id)init
{
	if (self = [super init])
	{
		contentScale = 1.0;
	}
	return self;
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	CGRect frame = layer.frame;
	// Scale frame width up from 2 to frame.size.width
	self.contentScale = frame.size.width/2.0;
	CATransform3D frameTransform = CATransform3DMakeScale(contentScale, contentScale, 1);
	CGPoint anchor = CGPointMake(frame.origin.x + frame.size.width/2.0,
								 frame.origin.y + frame.size.height);
	CGRect bounds = CGRectMake(-1.0, -frame.size.height/contentScale,
							   2.0, frame.size.height/contentScale);
	for (CALayer * sublayer in layer.sublayers)
	{
		sublayer.position = anchor;
		sublayer.bounds = bounds;
		sublayer.transform = frameTransform;
	}
	[CATransaction commit];
}

@synthesize contentScale;

@end
