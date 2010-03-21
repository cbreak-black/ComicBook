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

// Helpers
CG_INLINE CGPoint CBClampPointToRect(CGPoint p, CGRect r)
{
	CGFloat minX = r.origin.x;
	CGFloat maxX = CGRectGetMaxX(r);
	CGFloat minY = r.origin.y;
	CGFloat maxY = CGRectGetMaxY(r);
	p.x = minX > p.x ? minX : p.x;
	p.x = maxX < p.x ? maxX : p.x;
	p.y = minY > p.y ? minY : p.y;
	p.y = maxY < p.y ? maxY : p.y;
	return p;
}

// Scales a rectangle r by factor f with anchor a.
// a is expected to be normalized to [0,1]
//CG_INLINE CGRect CBScaleRectWithAnchorByFactor(CGRect r, CGPoint a, CGFloat f)
//{
//	CGSize change;
//	change.width = r.size.width*f - r.size.width;
//	change.height = r.size.height*f - r.size.height;
//	r.origin.x -= a.x*change.width;
//	r.size.width += (1-a.x)*change.width;
//	r.origin.y -= a.y*change.height;
//	r.size.height += (1-a.y)*change.height;
//	return r;
//}

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
	CBLayout lt;
	if ([l isEqualToString:kCBLayoutSingle])
		lt = CBLayoutSingle;
	else if ([l isEqualToString:kCBLayoutLeft])
		lt = CBLayoutLeft;
	else
		lt = CBLayoutRight;
	// Scale
	NSString * s = [ud stringForKey:kCBScaleKey];
	CBScale st;
	if ([s isEqualToString:kCBScaleOriginal])
		st = CBScaleOriginal;
	else if ([s isEqualToString:kCBScaleFull])
		st = CBScaleFull;
	else
		st = CBScaleWidth;
	// Relayout
	BOOL changed = NO;
	if (layout != lt)
	{
		layout = lt;
		changed = YES;
	}
	if (scale != st)
	{
		scale = st;
		changed = YES;
	}
	if (changed)
		[self pageChanged];
}

// Events

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)moveUp:(id)sender
{
	CGSize windowSize = scrollLayer.bounds.size;
	[self scrollByOffsetX:0 Y:+windowSize.height*0.5];
}

- (void)moveDown:(id)sender
{
	CGSize windowSize = scrollLayer.bounds.size;
	[self scrollByOffsetX:0 Y:-windowSize.height*0.5];
}

- (void)moveLeft:(id)sender
{
	CGSize windowSize = scrollLayer.bounds.size;
	[self scrollByOffsetX:-windowSize.width*0.5 Y:0];
}

- (void)moveRight:(id)sender
{
	CGSize windowSize = scrollLayer.bounds.size;
	[self scrollByOffsetX:+windowSize.width*0.5 Y:0];
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
	// Only care about certain modifiers
	NSUInteger modifierMask = NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask;
	NSUInteger modifiers = [theEvent modifierFlags] & modifierMask;
	if (modifiers == 0)
	{
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
			case '+':
				[self zoomIn];
				break;
			case '-':
				[self zoomOut];
				break;
			default:
				return [super performKeyEquivalent:theEvent];
				break;
		}
		return YES;
	}
	return [super performKeyEquivalent:theEvent];
}

@synthesize delegate;

- (void)defaultsChanged:(NSNotification *)notification
{
	NSUserDefaults * ud = [notification object];
	[self loadDefaults:ud];
}

// Resizing
- (void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSize
{
	[super resizeWithOldSuperviewSize:oldBoundsSize];
	[self resetView];
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
	scrollLayer.anchorPoint = CGPointMake(0.5, 1.0);
	scrollLayer.frame = backgroundLayer.frame;
	scrollLayer.autoresizingMask = (kCALayerWidthSizable | kCALayerHeightSizable);
	[backgroundLayer addSublayer:scrollLayer];

	// Content layer
	containerLayer = [[CALayer alloc] init];
	containerLayer.anchorPoint = CGPointMake(0.5, 1.0);
	containerLayer.contentsGravity = kCAGravityTop;
	containerLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
	[scrollLayer addSublayer:containerLayer];

	pageLayerLeft = [[CALayer alloc] init];
	pageLayerRight = [[CALayer alloc] init];
	pageLayerLeft.name = @"pageLayerLeft";
	pageLayerRight.name = @"pageLayerRight";
	pageLayerLeft.anchorPoint = CGPointMake(1.0, 1.0);
	pageLayerRight.anchorPoint = CGPointMake(0.0, 1.0);
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

	scrollLayer.delegate = self;
	containerLayer.delegate = self;
	pageLayerLeft.delegate = self;
	pageLayerRight.delegate = self;

	// Cleanup
	[backgroundLayer release];
	CGColorRelease(blackColor);
}

- (id < CAAction >)actionForLayer:(CALayer*)layer forKey:(NSString*)event
{
	// No animations when resizing
	if ([self inLiveResize])
	{
		return [CAAnimation animation];
	}
	return nil;
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
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	CGRect pageRect = CGRectMake(0, 0, 0, 0);
	// Container
	pageRect.size = page.size;
	containerLayer.bounds = pageRect;
	containerLayer.contents = page.image;
	CGSize slSize = scrollLayer.bounds.size;
	containerLayer.position = CGPointMake(slSize.width/2, slSize.height);
	// Left & Right
	pageLayerLeft.bounds = CGRectMake(0, 0, 0, 0);
	pageLayerRight.bounds = CGRectMake(0, 0, 0, 0);
	pageLayerLeft.contents = nil;
	pageLayerRight.contents = nil;
	pageDisplayCount = 1;
	[self resetView];
	[CATransaction commit];
}

- (void)setPageLeft:(CBPage*)pageLeft right:(CBPage*)pageRight
{
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
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
	[self resetView];
	[CATransaction commit];
}

// Scrolling & Zooming
- (void)resetView
{
	// TODO: Move to layout class
	CGSize slSize = scrollLayer.bounds.size;
	containerLayer.position = CGPointMake(slSize.width/2, slSize.height);
	if (layout == CBLayoutLeft)
		[self scrollToPoint:CGPointMake(-CGFLOAT_MAX, 0)];
	else
		[self scrollToPoint:CGPointMake(+CGFLOAT_MAX, 0)];
	[self zoomReset];
}

- (void)scrollToPoint:(CGPoint)point
{
	// Assumes container maxY to be at maxY of scrollLayer
	// Assumes container midX to be at midX of scrollLayer
	CGSize scrollSize = scrollLayer.bounds.size;
	CGSize containerSize = containerLayer.bounds.size;
	containerSize.width *= zoomFactor;
	containerSize.height *= zoomFactor;
	CGRect scrollBounds;
	if (containerSize.width < scrollSize.width)
	{
		// No scrolling horizontally
		scrollBounds.size.width = 0;
		scrollBounds.origin.x = 0;
	}
	else
	{
		scrollBounds.size.width = containerSize.width - scrollSize.width;
		scrollBounds.origin.x = -scrollBounds.size.width/2;
	}
	if (containerSize.height < scrollSize.height)
	{
		// No scrolling vertically
		scrollBounds.size.height = 0;
		scrollBounds.origin.y = 0;
	}
	else
	{
		scrollBounds.size.height = containerSize.height - scrollSize.height;
		scrollBounds.origin.y = -scrollBounds.size.height;
	}
	scrollPosition = CBClampPointToRect(point, scrollBounds);
	[scrollLayer scrollToPoint:scrollPosition];
}

- (void)scrollByOffsetX:(float)x Y:(float)y
{
	CGPoint p = scrollPosition;
	p.x += x;
	p.y += y;
	[self scrollToPoint:p];
}

- (void)zoomIn
{
	CGFloat newZoomFactor;
	if (zoomFactor < 0.25) newZoomFactor = zoomFactor*2.0;
	else newZoomFactor = zoomFactor + 0.125;
	[self zoomTo:newZoomFactor];
}

- (void)zoomOut
{
	CGFloat newZoomFactor;
	if (zoomFactor < 0.25) newZoomFactor = zoomFactor*0.5;
	else newZoomFactor = zoomFactor - 0.125;
	[self zoomTo:newZoomFactor];
}

- (void)zoomTo:(float)scaleFactor
{
	zoomFactor = scaleFactor;
	[containerLayer setValue:[NSNumber numberWithFloat:zoomFactor] forKeyPath:@"transform.scale"];
	[self scrollByOffsetX:0 Y:0];
}

- (void)zoomReset
{
	if (scale == CBScaleOriginal)
	{
		[self zoomTo:1.0];
	}
	else if (scale == CBScaleWidth)
	{
		float factor = scrollLayer.bounds.size.width/containerLayer.bounds.size.width;
		[self zoomTo:factor];
	}
	else // scale == CBScaleFull
	{
		float factorW = scrollLayer.bounds.size.width/containerLayer.bounds.size.width;
		float factorH = scrollLayer.bounds.size.height/containerLayer.bounds.size.height;
		if (factorH > factorW)
			[self zoomTo:factorW];
		else
			[self zoomTo:factorH];
	}
}

// Full Screen
- (IBAction)toggleFullscreen:(id)sender
{
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	if ([self isInFullScreenMode])
		[self exitFullScreen];
	else
		[self enterFullScreen];
	[CATransaction commit];
}

- (BOOL)enterFullScreen
{
	NSNumber * flags = [NSNumber numberWithUnsignedInteger:(NSApplicationPresentationHideDock | NSApplicationPresentationAutoHideMenuBar)];
	NSMutableDictionary * d = [NSMutableDictionary dictionaryWithCapacity:2];
	[d setValue:flags
		 forKey:NSFullScreenModeApplicationPresentationOptions];
	[d setValue:[NSNumber numberWithBool:NO]
		 forKey:NSFullScreenModeAllScreens];
	BOOL r = [self enterFullScreenMode:[self.window screen] withOptions:d];
	if (r)
		[self resetView];
	return r;
}

- (void)exitFullScreen
{
	[self exitFullScreenModeWithOptions:NULL];
	[[self window] makeFirstResponder:self];
	[self resetView];
}

@end
