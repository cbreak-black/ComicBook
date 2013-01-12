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
	}
	return self;
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	CGRect frame = layer.frame;
	CGPoint anchor = CGPointMake(frame.origin.x + frame.size.width/2.0,
								 frame.origin.y + frame.size.height);
	CGRect bounds = CGRectMake(-frame.size.width/2.0, -frame.size.height,
							   frame.size.width, frame.size.height);
	// Change width to be 2
	CGFloat frameScale = frame.size.width/2.0;
	CATransform3D frameTransform = CATransform3DMakeScale(frameScale, frameScale, 1);
	for (CALayer * sublayer in layer.sublayers)
	{
		sublayer.position = anchor;
		sublayer.bounds = bounds;
		sublayer.sublayerTransform = frameTransform;
	}
	[CATransaction commit];
}

@end
