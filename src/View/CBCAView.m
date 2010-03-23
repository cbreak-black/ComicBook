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

@interface CBCAView (CBInternal)

// Setup
- (void)configureLayers;
- (void)configurePageLayers:(CBCAViewLayerSet *)index;
- (void)loadDefaults:(NSUserDefaults *)ud;

@end


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
		scrollPosition = CGPointMake(0, 0);
		zoomFactor = 1.0;
		for (unsigned int i = 0; i < 3; i++)
		{
			layers[i].page1 = nil;
			layers[i].page2 = nil;
			layers[i].container = nil;
			layers[i].left = nil;
			layers[i].right = nil;
		}
		currentLayerSet = 0;
		delegate = nil;
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
	for (unsigned int i = 0; i < 3; i++)
	{
		[layers[i].page1 release];
		[layers[i].page2 release];
		[layers[i].right release];
		[layers[i].left release];
		[layers[i].container release];
	}
	[super dealloc];
}

- (void)awakeFromNib
{
	[self configureLayers];
}

// UI
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
	scrollLayer.delegate = self;
	[backgroundLayer addSublayer:scrollLayer];

	for (unsigned int i = 0; i < 3; i++)
		[self configurePageLayers:&layers[i]];

	// Cleanup
	[backgroundLayer release];
	CGColorRelease(blackColor);
}

- (void)configurePageLayers:(CBCAViewLayerSet *)cls
{
	// Content layer
	cls->container = [[CALayer alloc] init];
	cls->container.anchorPoint = CGPointMake(0.5, 1.0);
	cls->container.contentsGravity = kCAGravityTop;
	cls->container.layoutManager = [CAConstraintLayoutManager layoutManager];
	cls->container.delegate = self;
	[scrollLayer addSublayer:cls->container];

	cls->left = [[CALayer alloc] init];
	cls->right = [[CALayer alloc] init];
	cls->left.name = @"pageLayerLeft";
	cls->right.name = @"pageLayerRight";
	cls->left.anchorPoint = CGPointMake(1.0, 1.0);
	cls->right.anchorPoint = CGPointMake(0.0, 1.0);
	cls->left.contentsGravity = kCAGravityTopRight;
	cls->right.contentsGravity = kCAGravityTopLeft;
	[cls->left addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY
														relativeTo:@"superlayer"
												attribute:kCAConstraintMaxY]];
	[cls->left addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX
														relativeTo:@"superlayer"
														 attribute:kCAConstraintMinX]];
	[cls->right addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY
														 relativeTo:@"superlayer"
														  attribute:kCAConstraintMaxY]];
	[cls->right addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX
														 relativeTo:@"pageLayerLeft"
														  attribute:kCAConstraintMaxX]];
	[cls->container addSublayer:cls->left];
	[cls->container addSublayer:cls->right];
	cls->left.delegate = self;
	cls->right.delegate = self;
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
	if (layout != lt)
	{
		layout = lt;
		[self pageChanged];
	}
	if (scale != st)
	{
		scale = st;
		[self zoomReset];
	}
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
	unsigned char offset = layers[currentLayerSet].page2 == nil ? 1 : 2;
	[delegate advancePage:offset];
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
	NSString * eventKey = [theEvent charactersIgnoringModifiers];
	// Only care about certain modifiers
	NSUInteger modifierMask = NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask;
	NSUInteger modifiers = [theEvent modifierFlags] & modifierMask;
	unichar c = [eventKey characterAtIndex:0];
	if (modifiers == 0)
	{
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
			case 0xF72C:
				[self pageUp:self];
				break;
			case 0xF72D:
				[self pageDown:self];
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
	else if (modifiers == NSShiftKeyMask)
	{
		switch (c)
		{
			case 0xF72C:
				[delegate advancePage:-1];
				break;
			case 0xF72D:
				[delegate advancePage:+1];
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
- (void)resized
{
	// Consider using a layout manager instead
	CGSize slSize = scrollLayer.bounds.size;
	layers[currentLayerSet].container.position = CGPointMake(slSize.width/2, slSize.height);
	[self zoomReset];
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSize
{
	[super resizeWithOldSuperviewSize:oldBoundsSize];
	[self resized];
}

// Animation
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
	if (!delegate) return;
	// Prepare for page change animation
	CGFloat lastZoomFactor = zoomFactor;
	CGPoint lastScrollPosition = scrollPosition;
	unsigned char lastLayerSet = currentLayerSet;
	currentLayerSet = (currentLayerSet+1)%3;
	unsigned char nextLayerSet = (currentLayerSet+1)%3;
	// Change page
	NSUInteger cp = [delegate currentPage];
	NSUInteger lp = layers[lastLayerSet].page1.number;
	CBPage * page1 = [delegate pageAtIndex:cp];
	if (layout != CBLayoutSingle && page1.aspect < 1) // Two Page
	{
		CBPage * page2 = [delegate pageAtIndex:(cp+1)];
		if (page2 && page2.aspect < 1)
		{
			[self setPageOne:page1 two:page2];
		}
		else
		{
			[self setPage:page1];
		}
	}
	else
	{
		[self setPage:page1];
	}
	// Animate (Start)
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	CGSize slSize = scrollLayer.bounds.size;
	CGFloat hLast = layers[lastLayerSet].container.bounds.size.height*lastZoomFactor;
	if (hLast < slSize.height) hLast = slSize.height;
	CGFloat hNow = layers[currentLayerSet].container.bounds.size.height*zoomFactor;
	if (hNow < slSize.height) hNow = slSize.height;
	if (lp < cp)
	{
		// Scroll down
		layers[lastLayerSet].container.position = CGPointMake(slSize.width/2, slSize.height + hLast);
		[scrollLayer scrollToPoint:CGPointMake(lastScrollPosition.x, lastScrollPosition.y+hLast)];
	}
	else if (lp > cp)
	{
		// Scroll up
		layers[lastLayerSet].container.position = CGPointMake(slSize.width/2, slSize.height - hNow);
		[scrollLayer scrollToPoint:CGPointMake(lastScrollPosition.x, lastScrollPosition.y-hNow)];
	}
	layers[currentLayerSet].container.zPosition = 0.0;
	layers[currentLayerSet].container.hidden = NO;
	layers[nextLayerSet].container.hidden = YES;
	[CATransaction commit];
	// Animate (End)
	[CATransaction begin];
	layers[lastLayerSet].container.zPosition = -1.0;
	[CATransaction setValue:[NSNumber numberWithFloat:1.0]
					 forKey:kCATransactionAnimationDuration];
	// For cleanup
	[CATransaction setCompletionBlock:^{
		[CATransaction begin];
		[CATransaction setDisableActions:YES];
		layers[lastLayerSet].container.hidden = YES;
		[CATransaction commit];
	}
	 ];
	if (layout == CBLayoutLeft)
		[self scrollToPoint:CGPointMake(-CGFLOAT_MAX, 0)];
	else
		[self scrollToPoint:CGPointMake(+CGFLOAT_MAX, 0)];
	[CATransaction commit];
	// Resize window
	if (![self isInFullScreenMode])
	{
		CGSize currentSize = layers[currentLayerSet].container.bounds.size;
		NSWindow * window = self.window;
		NSRect contentRect = [window contentRectForFrameRect:[window frame]];
		if (scale == CBScaleFull)
		{
			CGFloat newHeight = contentRect.size.width*currentSize.height/currentSize.width;
			contentRect.origin.y = contentRect.origin.y + contentRect.size.height - newHeight;
			contentRect.size.height = newHeight;
			[window setContentAspectRatio:NSSizeFromCGSize(currentSize)];
			[window setFrame:[window frameRectForContentRect:contentRect] display:YES animate:NO];
		}
		else if (scale == CBScaleOriginal)
		{
			NSRect screenRect = [window.screen visibleFrame];
			contentRect.origin.y = contentRect.origin.y + contentRect.size.height - currentSize.height;
			contentRect.size = NSSizeFromCGSize(currentSize);
			NSRect windowRect = [window frameRectForContentRect:contentRect];
			windowRect = NSIntersectionRect(screenRect, windowRect);
			[window setResizeIncrements:NSMakeSize(1.0,1.0)];
			[window setFrame:windowRect display:YES animate:NO];
		}
		else
		{
			[window setResizeIncrements:NSMakeSize(1.0,1.0)];
		}
	}
}

- (void)setPage:(CBPage*)page
{
	[self setPage:page inSet:currentLayerSet];
}

- (void)setPage:(CBPage*)page inSet:(unsigned char)index
{
	if (index > 2) return;
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	CBCAViewLayerSet * cls = &layers[index];
	CGRect pageRect = CGRectMake(0, 0, 0, 0);
	// Container
	pageRect.size = NSSizeToCGSize(page.size);
	cls->container.bounds = pageRect;
	cls->container.contents = page.image;
	CGSize slSize = scrollLayer.bounds.size;
	cls->container.position = CGPointMake(slSize.width/2, slSize.height);
	// Left & Right
	cls->left.bounds = CGRectMake(0, 0, 0, 0);
	cls->right.bounds = CGRectMake(0, 0, 0, 0);
	cls->left.contents = nil;
	cls->right.contents = nil;
	// Pages
	[cls->page1 release];
	[cls->page2 release];
	cls->page1 = [page retain];
	cls->page2 = nil;
	[self zoomReset];
	[CATransaction commit];
}

- (void)setPageOne:(CBPage*)page1 two:(CBPage*)page2
{
	[self setPageOne:page1 two:page2 inSet:currentLayerSet];
}

- (void)setPageOne:(CBPage*)page1 two:(CBPage*)page2 inSet:(unsigned char)index
{
	if (index > 2) return;
	CBPage * pageLeft;
	CBPage * pageRight;
	if (layout == CBLayoutLeft)
	{
		pageLeft = page1;
		pageRight = page2;
	}
	else
	{
		pageLeft = page2;
		pageRight = page1;
	}
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	CBCAViewLayerSet * cls = &layers[index];
	CGRect pageRect = CGRectMake(0, 0, 0, 0);
	float pageWidth = 0;
	float pageHeight = 0;
	// Left
	pageRect.size = NSSizeToCGSize(pageLeft.size);
	pageWidth = pageRect.size.width;
	pageHeight = pageRect.size.height;
	cls->left.bounds = pageRect;
	cls->left.contents = pageLeft.image;
	// Right
	pageRect.size = NSSizeToCGSize(pageRight.size);
	pageWidth += pageRect.size.width;
	if (pageHeight < pageRect.size.height)
		pageHeight = pageRect.size.height;
	cls->right.bounds = pageRect;
	cls->right.contents = pageRight.image;
	// Container
	CGSize slSize = scrollLayer.bounds.size;
	cls->container.bounds = CGRectMake(0, 0, pageWidth, pageHeight);
	cls->container.position = CGPointMake(slSize.width/2, slSize.height);
	cls->container.contents = nil;
	// Pages
	[cls->page1 release];
	[cls->page2 release];
	cls->page1 = [page1 retain];
	cls->page2 = [page2 retain];
	[self zoomReset];
	[CATransaction commit];
}

// Scrolling & Zooming
- (void)scrollToPoint:(CGPoint)point
{
	// Assumes container maxY to be at maxY of scrollLayer
	// Assumes container midX to be at midX of scrollLayer
	CGSize scrollSize = scrollLayer.bounds.size;
	CGSize containerSize = layers[currentLayerSet].container.bounds.size;
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
	[layers[currentLayerSet].container setValue:[NSNumber numberWithFloat:zoomFactor] forKeyPath:@"transform.scale"];
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
		float factor = scrollLayer.bounds.size.width/layers[currentLayerSet].container.bounds.size.width;
		[self zoomTo:factor];
	}
	else // scale == CBScaleFull
	{
		float factorW = scrollLayer.bounds.size.width/layers[currentLayerSet].container.bounds.size.width;
		float factorH = scrollLayer.bounds.size.height/layers[currentLayerSet].container.bounds.size.height;
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
	[self resized];
	return r;
}

- (void)exitFullScreen
{
	[self exitFullScreenModeWithOptions:NULL];
	[[self window] makeFirstResponder:self];
	[self resized];
}

@end
