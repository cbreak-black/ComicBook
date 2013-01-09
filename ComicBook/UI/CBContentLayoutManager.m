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
		zoom = 1.0;
		position = CGPointMake(0, 0);
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
	CATransform3D translate = CATransform3DMakeTranslation(position.x, position.y, 0);
	CATransform3D scale = CATransform3DMakeScale(zoom, zoom, 1);
	CATransform3D viewTransform = CATransform3DConcat(translate, scale);
	for (CALayer * sublayer in layer.sublayers)
	{
		sublayer.position = anchor;
		sublayer.bounds = bounds;
		sublayer.sublayerTransform = frameTransform;
	}
	layer.sublayerTransform = viewTransform;
	[CATransaction commit];
}

@synthesize zoom;
@synthesize position;

@end
