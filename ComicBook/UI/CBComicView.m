//
//  CBComicView.m
//  ComicBook
//
//  Created by cbreak on 2012.12.23.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBComicView.h"

#import "CBRangeBuffer.h"
#import "CBPageLayer.h"
#import "CBComicModel.h"

@implementation CBComicView

- (id)initWithFrame:(NSRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		pages = [[CBRangeBuffer alloc] init];
	}
	return self;
}

- (void)awakeFromNib
{
	[self configureLayers];
}

- (void)configureLayers
{
	// Background layer
	backgroundLayer = [[CALayer alloc] init];
	CGColorRef bgColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
	backgroundLayer.backgroundColor = bgColor;
	[self setLayer:backgroundLayer];
	[self setWantsLayer:YES];
	// Page Layers
	for (NSUInteger i = 0; i < 32; ++i)
	{
		CBPageLayer * pageLayer = [[CBPageLayer alloc]init];
		[pages addObject:pageLayer];
		[backgroundLayer addSublayer:pageLayer];
	}
	// Cleanup
	CGColorRelease(bgColor);
}

- (void)setModel:(CBComicModel *)model_
{
	model = model_;
	[pages enumerateObjectsUsingBlockAsync:^(id obj, NSInteger idx)
	{
		CBPageLayer * pageLayer = obj;
		if (idx >= 0)
		{
			[CATransaction begin];
			[CATransaction setDisableActions:YES];
			pageLayer.comicBookFrame = [model frameAtIndex:idx];
			[CATransaction commit];
		}
	}];
}

@synthesize model;

@end
