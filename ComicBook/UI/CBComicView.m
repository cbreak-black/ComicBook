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

#import <QuartzCore/CoreImage.h>

static const NSInteger kCBPageCacheCountFwd = 32;
static const NSInteger kCBPageCacheCountBwd = 8;
static const CGFloat kCBCoarseLineFactor = 32.0;

@implementation CBComicView

- (id)initWithFrame:(NSRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		pages = [[CBRangeBuffer alloc] init];
		contentLayoutManager = [[CBContentLayoutManager alloc] init];
		comicLayoutManager = [[CBComicLayoutManager alloc] initWithPages:pages];
		// Default View State
		zoom = 1.0;
		position = CGPointMake(0, 0);
		// Configuration
		[self configureLayers];
		[self configureFilters];
	}
	return self;
}

- (void)dealloc
{
	self.model = nil;
}

- (void)awakeFromNib
{
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
	contentLayer = [[CALayer alloc] init];
	contentLayer.anchorPoint = CGPointMake(0.5, 1.0);
	contentLayer.layoutManager = comicLayoutManager;
	[backgroundLayer addSublayer:contentLayer];
	for (NSUInteger i = 0; i < kCBPageCacheCountFwd + kCBPageCacheCountBwd; ++i)
	{
		CBPageLayer * pageLayer = [[CBPageLayer alloc] init];
		[pages addObject:pageLayer];
		[contentLayer addSublayer:pageLayer];
	}
	[pages setStartIndex:-kCBPageCacheCountBwd];
	// Cleanup
	CGColorRelease(bgColor);
}

- (void)configureFilters
{
	// Gamma Correction
	gammaFilter = [CIFilter filterWithName:@"CIGammaAdjust"];
	[self setGammaPower:1.0]; // 0.1 - 3.0
	// Registering
	backgroundLayer.filters = @[gammaFilter];
}

- (CGFloat)gammaPower
{
	return [[gammaFilter valueForKey:@"inputPower"] doubleValue];
}

- (void)setGammaPower:(CGFloat)gammaPower
{
	[gammaFilter setValue:[NSNumber numberWithDouble:gammaPower] forKey:@"inputPower"];
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
		[pages enumerateObjectsUsingBlockAsync:^(id obj, NSInteger idx)
		{
			CBPageLayer * pageLayer = obj;
			[CATransaction begin];
			[CATransaction setDisableActions:YES];
			pageLayer.comicBookFrame = [model frameAtIndex:idx];
			[CATransaction commit];
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

- (void)zoomBy:(CGFloat)factor
{
	zoom *= factor;
	[self setNeedsViewTransformUpdate];
}

- (void)moveBy:(CGPoint)offset
{
	position.x += offset.x/contentLayoutManager.contentScale;
	position.y += offset.y/contentLayoutManager.contentScale;
	[self setNeedsViewTransformUpdate];
}

- (void)setZoom:(CGFloat)zoom_
{
	zoom = zoom_;
	[self setNeedsViewTransformUpdate];
}

- (void)setPosition:(CGPoint)position_
{
	position = position_;
	[self setNeedsViewTransformUpdate];
}

@synthesize zoom;
@synthesize position;

- (void)setNeedsViewTransformUpdate
{
	[self clampViewTransformState];
	[self updateViewTransform];
}

- (void)clampViewTransformState
{
	if      (zoom < 0.20) zoom = 0.20;
	else if (zoom > 5.00) zoom = 5.00;
	CGRect bounds = contentLayer.bounds;
	CGFloat hLimit = fabs(bounds.size.width/2*(1.0-1.0/zoom));
	// position y is flipped
	CGFloat vLimitTop = -comicLayoutManager.verticalTop;
	CGFloat vLimitBottom = -comicLayoutManager.verticalBottom-bounds.size.height/zoom;
	if (vLimitBottom < vLimitTop) vLimitBottom = vLimitTop;
	if      (position.x < -hLimit) position.x = -hLimit;
	else if (position.x > +hLimit) position.x = +hLimit;
	if      (position.y < vLimitTop) position.y = vLimitTop;
	else if (position.y > vLimitBottom) position.y = vLimitBottom;
}

- (void)updateViewTransform
{
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	CATransform3D scale = CATransform3DMakeScale(zoom, zoom, 1);
	CATransform3D translate = CATransform3DMakeTranslation(position.x, position.y, 0);
	CATransform3D viewTransform = CATransform3DConcat(translate, scale);
	contentLayer.sublayerTransform = viewTransform;
	[CATransaction commit];
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)resignFirstResponder
{
	return NO;
}

- (void)mouseDown:(NSEvent*)event
{
}

- (void)mouseDragged:(NSEvent*)event
{
	[self moveBy:CGPointMake([event deltaX]/zoom, -[event deltaY]/zoom)];
}

- (void)mouseMoved:(NSEvent*)event
{
}

- (void)mouseUp:(NSEvent*)event
{
}

- (void)scrollWheel:(NSEvent*)event
{
	if ([event modifierFlags] & NSShiftKeyMask)
	{
		CGFloat offset = [event scrollingDeltaX]-[event scrollingDeltaY];
		if (![event hasPreciseScrollingDeltas])
			offset *= kCBCoarseLineFactor;
		CGFloat factor = pow(0.999, offset);
		[self zoomBy:factor];
	}
	else
	{
		if ([event hasPreciseScrollingDeltas])
			[self moveBy:CGPointMake(+[event scrollingDeltaX],
									 -[event scrollingDeltaY])];
		else
			[self moveBy:CGPointMake(+[event scrollingDeltaX]*kCBCoarseLineFactor,
									 -[event scrollingDeltaY]*kCBCoarseLineFactor)];
	}
}

- (void)keyDown:(NSEvent*)event
{
	NSLog(@"%@", event);
}

- (void)keyUp:(NSEvent*)event
{
	NSLog(@"%@", event);
}

- (void)swipeWithEvent:(NSEvent*)event
{
	NSLog(@"%@", event);
}

@end
