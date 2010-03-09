//
//  CBCAView.m
//  ComicBook
//
//  Created by cbreak on 09.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBCAView.h"


@implementation CBCAView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
	}
    return self;
}

- (void)dealloc
{
	[containerLayer release];
	[pageLayerLeft release];
	[pageLayerRight release];
	[super dealloc];
}

- (void)awakeFromNib
{
	[self configureLayers];
}

- (void)configureLayers
{
	// Background layer
	CALayer * backgroundLayer = [[CALayer alloc] init];
	CGColorRef blackColor=CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
	backgroundLayer.backgroundColor = blackColor;
	[self setLayer:backgroundLayer];
	[self setWantsLayer:YES];

	// Content layer
	containerLayer = [[CALayer alloc] init];
	containerLayer.frame = backgroundLayer.frame;
	containerLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
	[backgroundLayer addSublayer:containerLayer];

	// Cleanup
	[backgroundLayer release];
}


@end
