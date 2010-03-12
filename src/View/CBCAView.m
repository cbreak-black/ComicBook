//
//  CBCAView.m
//  ComicBook
//
//  Created by cbreak on 09.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBCAView.h"

#import "CBInputDelegate.h"

#import "CBPage.h"

@implementation CBCAView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		pageDisplayCount = 0;
		scrollPosition = CGPointMake(0, 0);
	}
    return self;
}

- (void)dealloc
{
	[scrollLayer release];
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
	[self scrollByOffsetX:0 Y:+100];
}

- (void)moveDown:(id)sender
{
	[self scrollByOffsetX:0 Y:-100];
}

- (void)moveLeft:(id)sender
{
	[self scrollByOffsetX:-100 Y:0];
}

- (void)moveRight:(id)sender
{
	[self scrollByOffsetX:+100 Y:0];
}

- (void)pageUp:(id)sender
{
	// TODO: Consider user settings
	// Decide if displaying one or two pages is better
	NSUInteger cp = [delegate currentPage];
	CBPage * page1 = [delegate pageAtIndex:cp-1];
	CBPage * page2 = [delegate pageAtIndex:cp-2];
	if (page1 && page2 && page1.aspect < 1 && page2.aspect < 1)
		[delegate advancePage:-2];
	else
		[delegate advancePage:-1];
}

- (void)pageDown:(id)sender
{
	[delegate advancePage:pageDisplayCount];
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
	NSString * eventKey = [theEvent charactersIgnoringModifiers];
	NSUInteger modifiers = [theEvent modifierFlags];
	unichar c = [eventKey characterAtIndex:0];
	switch (c)
	{
		case 0xF729:
			[delegate setCurrentPage:0];
			break;
		case 0xF72B:
			[delegate setCurrentPage:NSUIntegerMax];
			break;
		default:
			return [super performKeyEquivalent:theEvent];
			break;
	}
	return YES;
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

	// Scroll Layer
	scrollLayer = [[CAScrollLayer alloc] init];
	scrollLayer.frame = backgroundLayer.frame;
	scrollLayer.autoresizingMask = (kCALayerWidthSizable | kCALayerHeightSizable);
	[backgroundLayer addSublayer:scrollLayer];

	// Content layer
	containerLayer = [[CALayer alloc] init];
	containerLayer.frame = backgroundLayer.frame;
	containerLayer.contentsGravity = kCAGravityTop;
	containerLayer.autoresizingMask = (kCALayerMinXMargin | kCALayerMaxXMargin | kCALayerHeightSizable);
	containerLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
	[scrollLayer addSublayer:containerLayer];

	pageLayerLeft = [[CALayer alloc] init];
	pageLayerRight = [[CALayer alloc] init];
	pageLayerLeft.name = @"pageLayerLeft";
	pageLayerRight.name = @"pageLayerRight";
	pageLayerLeft.contentsGravity = kCAGravityTopRight;
	pageLayerRight.contentsGravity = kCAGravityTopLeft;
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
	scrollLayer.actions = customActions;
	containerLayer.actions = customActions;
	pageLayerLeft.actions = customActions;
	pageLayerRight.actions = customActions;

	// Cleanup
	[backgroundLayer release];
}

- (void)pageChanged
{
	// TODO: Rewrite to consider user settings
	NSUInteger cp = [delegate currentPage];
	CBPage * page1 = [delegate pageAtIndex:cp];
	if (page1.aspect < 1) // Two Page
	{
		CBPage * page2 = [delegate pageAtIndex:(cp+1)];
		if (page2 && page2.aspect < 1)
		{
			[self setImageLeft:page1.image right:page2.image];
			return;
		}
	}
	[self setImage:page1.image];
}

- (void)setImage:(NSImage*)img
{
	pageLayerLeft.contents = nil;
	pageLayerRight.contents = nil;
	containerLayer.contents = img;
	pageDisplayCount = 1;
	[self scrollToPoint:CGPointMake(0, 0)];
}

- (void)setImageLeft:(NSImage*)imgLeft right:(NSImage*)imgRight
{
	containerLayer.contents = nil;
	pageLayerLeft.contents = imgLeft;
	pageLayerRight.contents = imgRight;
	pageDisplayCount = 2;
	[self scrollToPoint:CGPointMake(0, 0)];
}

- (void)scrollToPoint:(CGPoint)point
{
	scrollPosition = point;
	[scrollLayer scrollToPoint:scrollPosition];
}

- (void)scrollByOffsetX:(float)x Y:(float)y
{
	scrollPosition.x += x;
	scrollPosition.y += y;
	[scrollLayer scrollToPoint:scrollPosition];
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
