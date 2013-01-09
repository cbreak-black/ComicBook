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

#include "CBContentLayoutManager.h"
#include "CBComicLayoutManager.h"

@implementation CBComicView

- (id)initWithFrame:(NSRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		pages = [[CBRangeBuffer alloc] init];
		contentLayoutManager = [[CBContentLayoutManager alloc] init];
		comicLayoutManager = [[CBComicLayoutManager alloc] initWithPages:pages];
	}
	return self;
}

- (void)dealloc
{
	self.model = nil;
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
	backgroundLayer.layoutManager = contentLayoutManager;
	backgroundLayer.anchorPoint = CGPointMake(0.5, 0.5);
	[self setLayer:backgroundLayer];
	[self setWantsLayer:YES];
	// Page Layers
	contentLayer = [[CAScrollLayer alloc] init];
	contentLayer.anchorPoint = CGPointMake(0.5, 1.0);
	contentLayer.layoutManager = comicLayoutManager;
	[backgroundLayer addSublayer:contentLayer];
	for (NSUInteger i = 0; i < 32; ++i)
	{
		CBPageLayer * pageLayer = [[CBPageLayer alloc] init];
		[pages addObject:pageLayer];
		[contentLayer addSublayer:pageLayer];
	}
	// Cleanup
	CGColorRelease(bgColor);
}

- (void)setModel:(CBComicModel *)model_
{
	if (model != nil)
	{
		[model removeObserver:self forKeyPath:@"currentFrame"];
	}
	model = model_;
	if (model != nil)
	{
		[model addObserver:self forKeyPath:@"currentFrame" options:0 context:0];
		NSInteger endIdx = model.frameCount;
		[pages enumerateObjectsUsingBlockAsync:^(id obj, NSInteger idx)
		{
			CBPageLayer * pageLayer = obj;
			if (idx >= 0 && idx < endIdx)
			{
				[CATransaction begin];
				[CATransaction setDisableActions:YES];
				pageLayer.comicBookFrame = [model frameAtIndex:idx];
				[CATransaction commit];
			}
		}];
	}
}

@synthesize model;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
						change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"currentFrame"])
	{
		if (comicLayoutManager.anchorPageIndex != model.currentFrame)
		{
			// TODO: Advance range buffer
			// TODO: Update layout manager anchor page
		}
	}
}

@end
