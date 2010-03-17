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

// For User Defaults

// Layout
NSString * kCBLayoutKey = @"PageLayout";
NSString * kCBLayoutSingle = @"Single";
NSString * kCBLayoutLeft = @"LeftToRight";
NSString * kCBLayoutRight = @"RightToLeft";

// Scale
NSString * kCBScaleKey = @"Autoscale";
NSString * kCBScaleOriginal = @"Original";
NSString * kCBScaleWidth = @"FullWidth";
NSString * kCBScaleFull = @"FullPage";

@implementation CBCAView

+ (void)initialize
{
	NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
	NSDictionary * viewDefaults = [NSMutableDictionary dictionaryWithCapacity:4];
	[viewDefaults setValue:kCBLayoutRight forKey:kCBLayoutKey];
	[viewDefaults setValue:kCBScaleWidth forKey:kCBScaleKey];
	[ud registerDefaults:viewDefaults];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		pageDisplayCount = 0;
		scrollPosition = CGPointMake(0, 0);
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(defaultsChanged:)
													 name:NSUserDefaultsDidChangeNotification
												   object:nil];
		[self loadDefaults:[NSUserDefaults standardUserDefaults]];
	}
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)loadDefaults:(NSUserDefaults *)ud
{
	// Layout
	NSString * l = [ud stringForKey:kCBLayoutKey];
	if ([l isEqualToString:kCBLayoutSingle])
		layout = CBLayoutSingle;
	else if ([l isEqualToString:kCBLayoutLeft])
		layout = CBLayoutLeft;
	else
		layout = CBLayoutRight;
	// Scale
	NSString * s = [ud stringForKey:kCBScaleKey];
	if ([s isEqualToString:kCBScaleOriginal])
		scale = CBScaleOriginal;
	else if ([s isEqualToString:kCBScaleFull])
		scale = CBScaleFull;
	else
		scale = CBScaleWidth;
	// Relayout
	[self pageChanged];
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
	// Decide if displaying one or two pages is better
	if (layout == CBLayoutSingle)
	{
		[delegate advancePage:-1];
	}
	else
	{
		NSUInteger cp = [delegate currentPage];
		CBPage * page1 = [delegate pageAtIndex:cp-1];
		CBPage * page2 = [delegate pageAtIndex:cp-2];
		if (page1 && page2 && page1.aspect < 1 && page2.aspect < 1)
			[delegate advancePage:-2];
		else
			[delegate advancePage:-1];
	}
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
		case ' ':
			[self pageDown:self];
			break;
		case 'f':
			[self toggleFullscreen:self];
			break;
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

- (void)defaultsChanged:(NSNotification *)notification
{
	NSUserDefaults * ud = [notification object];
	[self loadDefaults:ud];
}

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
	containerLayer.anchorPoint = CGPointMake(0.5, 1.0);
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
	[pageLayerLeft addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY
															relativeTo:@"superlayer"
															 attribute:kCAConstraintMaxY]];
	[pageLayerLeft addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX
															relativeTo:@"superlayer"
															 attribute:kCAConstraintMinX]];
	[pageLayerRight addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY
															 relativeTo:@"superlayer"
															  attribute:kCAConstraintMaxY]];
	[pageLayerRight addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX
															 relativeTo:@"pageLayerLeft"
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
	NSUInteger cp = [delegate currentPage];
	CBPage * page1 = [delegate pageAtIndex:cp];
	if (layout != CBLayoutSingle && page1.aspect < 1) // Two Page
	{
		CBPage * page2 = [delegate pageAtIndex:(cp+1)];
		if (page2 && page2.aspect < 1)
		{
			if (layout == CBLayoutLeft)
				[self setPageLeft:page1 right:page2];
			else
				[self setPageLeft:page2 right:page1];
			return;
		}
	}
	[self setPage:page1];
}

- (void)setPage:(CBPage*)page
{
	CGRect pageRect = CGRectMake(0, 0, 0, 0);
	// Container
	pageRect.size = page.size;
	containerLayer.bounds = pageRect;
	containerLayer.contents = page.image;
	CGSize slSize = scrollLayer.bounds.size;
	containerLayer.position = CGPointMake(slSize.width/2, slSize.height);
	// Left & Right
	pageLayerLeft.contents = nil;
	pageLayerRight.contents = nil;
	pageDisplayCount = 1;
	[self scrollToPoint:CGPointMake(0, 0)];
}

- (void)setPageLeft:(CBPage*)pageLeft right:(CBPage*)pageRight
{
	CGRect pageRect = CGRectMake(0, 0, 0, 0);
	float pageWidth = 0;
	float pageHeight = 0;
	// Left
	pageRect.size = pageLeft.size;
	pageWidth = pageRect.size.width;
	pageHeight = pageRect.size.height;
	pageLayerLeft.bounds = pageRect;
	pageLayerLeft.contents = pageLeft.image;
	// Right
	pageRect.size = pageRight.size;
	pageWidth += pageRect.size.width;
	if (pageHeight < pageRect.size.height)
		pageHeight = pageRect.size.height;
	pageLayerRight.bounds = pageRect;
	pageLayerRight.contents = pageRight.image;
	// Container
	CGSize slSize = scrollLayer.bounds.size;
	containerLayer.bounds = CGRectMake(0, 0, pageWidth, pageHeight);
	containerLayer.position = CGPointMake(slSize.width/2, slSize.height);
	containerLayer.contents = nil;
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
	NSMutableDictionary * d = [NSMutableDictionary dictionaryWithCapacity:2];
	[d setValue:flags
		 forKey:NSFullScreenModeApplicationPresentationOptions];
	[d setValue:[NSNumber numberWithBool:NO]
		 forKey:NSFullScreenModeAllScreens];
	return [self enterFullScreenMode:[self.window screen] withOptions:d];
}

- (void)exitFullScreen
{
	[self exitFullScreenModeWithOptions:NULL];
	[[self window] makeFirstResponder:self];
}

@end
