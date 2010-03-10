//
//  CBCAView.m
//  ComicBook
//
//  Created by cbreak on 09.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBCAView.h"

#import "CBInputDelegate.h"

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

// Events

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)moveUp:(id)sender
{
	[delegate advancePage:-1];
}

- (void)moveDown:(id)sender
{
	[delegate advancePage:+1];
}

@synthesize delegate;

// UI / Animation

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
	containerLayer.contentsGravity = kCAGravityResizeAspect;
	containerLayer.autoresizingMask = (kCALayerWidthSizable | kCALayerHeightSizable);
	containerLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
	[backgroundLayer addSublayer:containerLayer];

	pageLayerLeft = [[CALayer alloc] init];
	pageLayerRight = [[CALayer alloc] init];
	pageLayerLeft.name = @"pageLayerLeft";
	pageLayerRight.name = @"pageLayerRight";
	pageLayerLeft.contentsGravity = kCAGravityResizeAspect;
	pageLayerRight.contentsGravity = kCAGravityResizeAspect;
	[pageLayerLeft addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY
															relativeTo:@"superlayer"
															 attribute:kCAConstraintMinY]];
	[pageLayerLeft addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY
															relativeTo:@"superlayer"
															 attribute:kCAConstraintMaxY]];
	[pageLayerLeft addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX
															relativeTo:@"superlayer"
															 attribute:kCAConstraintMinX]];
	[pageLayerLeft addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX
															relativeTo:@"superlayer"
															 attribute:kCAConstraintMidX]];
	[pageLayerRight addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY
															 relativeTo:@"superlayer"
															  attribute:kCAConstraintMinY]];
	[pageLayerRight addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY
															 relativeTo:@"superlayer"
															  attribute:kCAConstraintMaxY]];
	[pageLayerRight addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX
															 relativeTo:@"pageLayerLeft"
															  attribute:kCAConstraintMaxX]];
	[pageLayerRight addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX
															 relativeTo:@"superlayer"
															  attribute:kCAConstraintMaxX]];
	[containerLayer addSublayer:pageLayerLeft];
	[containerLayer addSublayer:pageLayerRight];

	// Disable animation for size changes
	NSMutableDictionary * customActions = [NSMutableDictionary dictionary];
	[customActions setObject:[NSNull null] forKey:@"bounds"];
	[customActions setObject:[NSNull null] forKey:@"position"];
	[customActions setObject:[NSNull null] forKey:@"frame"];
	containerLayer.actions = customActions;
	pageLayerLeft.actions = customActions;
	pageLayerRight.actions = customActions;

	// Cleanup
	[backgroundLayer release];
}

- (void)setImage:(NSImage*)img
{
	pageLayerLeft.contents = nil;
	pageLayerRight.contents = nil;
	containerLayer.contents = img;
}

- (void)setImageLeft:(NSImage*)imgLeft right:(NSImage*)imgRight
{
	containerLayer.contents = nil;
	pageLayerLeft.contents = imgLeft;
	pageLayerRight.contents = imgRight;
}

// Full Screen
- (IBAction)toggleFullscreen:(id)sender
{
	if ([self isInFullScreenMode])
		[self exitFullScreen];
	else
		[self enterFullScreen];
}

- (BOOL)enterFullScreen
{
	NSNumber * flags = [NSNumber numberWithUnsignedInteger:(NSApplicationPresentationHideDock | NSApplicationPresentationAutoHideMenuBar)];
	NSDictionary * d = [NSDictionary dictionaryWithObject:flags
												   forKey:NSFullScreenModeApplicationPresentationOptions];
	return [self enterFullScreenMode:[self.window screen] withOptions:d];
}

- (void)exitFullScreen
{
	[self exitFullScreenModeWithOptions:NULL];
	[[self window] makeFirstResponder:self];
}

@end
