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
		autoScrollPoints = [[NSMutableArray alloc] initWithCapacity:2];
		autoScrollIndex = 0;
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
	[autoScrollPoints release];
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
	backgroundLayer = [[CALayer alloc] init];
	CGColorRef blackColor=CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
	backgroundLayer.backgroundColor = blackColor;
	[self setLayer:backgroundLayer];
	[self setWantsLayer:YES];

	// Scroll Layer
	scrollLayer = [[CAScrollLayer alloc] init];
	scrollLayer.anchorPoint = CGPointMake(0.5, 1.0);
	scrollLayer.frame = backgroundLayer.frame;
	scrollLayer.autoresizingMask = (kCALayerWidthSizable | kCALayerHeightSizable);
	scrollLayer.masksToBounds = NO;
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
	[self scrollByOffsetX:0 Y:+windowSize.height*0.8];
}

- (void)moveDown:(id)sender
{
	CGSize windowSize = scrollLayer.bounds.size;
	[self scrollByOffsetX:0 Y:-windowSize.height*0.8];
}

- (void)moveLeft:(id)sender
{
	CGSize windowSize = scrollLayer.bounds.size;
	[self scrollByOffsetX:-windowSize.width*0.8 Y:0];
}

- (void)moveRight:(id)sender
{
	CGSize windowSize = scrollLayer.bounds.size;
	[self scrollByOffsetX:+windowSize.width*0.8 Y:0];
}

- (void)pageUp:(id)sender
{
	if (!delegate) return;
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
		[page1 beginContentAccess];
		[page2 beginContentAccess];
		if (page1 && page2 && page1.portrait && page2.portrait)
			[delegate advancePage:-2];
		else
			[delegate advancePage:-1];
		[page1 endContentAccess];
		[page2 endContentAccess];
	}
}

- (void)pageDown:(id)sender
{
	if (!delegate) return;
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
				[self autoScrollNext];
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

// Mouse
static const CGFloat scrollWheelFactor = 10.0;

- (void)scrollWheel:(NSEvent *)event
{
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	[self scrollByOffsetX:-event.deltaX*scrollWheelFactor Y:event.deltaY*scrollWheelFactor];
	[CATransaction commit];
}

- (void)mouseDown:(NSEvent *)event
{
	[super mouseDown:event];
}

- (void)mouseDragged:(NSEvent *)event
{
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	[self scrollByOffsetX:-event.deltaX Y:event.deltaY];
	[CATransaction commit];
}

- (void)mouseUp:(NSEvent *)event
{
	if (event.clickCount == 1)
	{
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue
						 forKey:kCATransactionDisableActions];
		// Click in view coordinates
		CGPoint clickPoint = NSPointToCGPoint([self convertPoint:[event locationInWindow] fromView:nil]);
		//CGPoint scrollPoint = [scrollLayer convertPoint:NSPointToCGPoint(clickPoint) fromLayer:backgroundLayer];
		CALayer * hitLayer = [backgroundLayer hitTest:clickPoint];
		[CATransaction commit];
		char direction = 1; // 0: back, 1: forward
		if (hitLayer == layers[currentLayerSet].left) // Left
			direction = layout == CBLayoutRight ? 1 : 0;
		else if (hitLayer == layers[currentLayerSet].right) // Right
			direction = layout == CBLayoutRight ? 0 : 1;
		// Change page
		if (direction == 0)
			[self pageUp:self];
		else
			[self pageDown:self];
	}
	else
	{
		[super mouseUp:event];
	}
}

- (void)rightMouseDown:(NSEvent *)event
{
	[super rightMouseDown:event];
}

static const CGFloat dragScaleFactor = 0.0025;

- (void)rightMouseDragged:(NSEvent *)event
{
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	CGFloat maganification = (event.deltaX+event.deltaY)*dragScaleFactor;
	[self zoomTo:zoomFactor*(1.0+maganification)];
	[CATransaction commit];
}

- (void)rightMouseUp:(NSEvent *)event
{
	[super rightMouseUp:event];
}

// Touch
static const CGFloat magnifyFactor = 0.5;

- (void)magnifyWithEvent:(NSEvent *)event
{
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	[self zoomTo:zoomFactor*(1.0+event.magnification*magnifyFactor)];
	[CATransaction commit];
}

- (void)rotateWithEvent:(NSEvent *)event
{
	NSLog(@"Rotate by %f", event.rotation);
	// Maybe rotation gets implemented later
}

- (void)swipeWithEvent:(NSEvent *)event
{
	char direction = 0; // 0: back, 1: forward
	// Vertical
	if (event.deltaY > 0) // Up
		direction = 0;
	else if (event.deltaY < 0) // Down
		direction = 1;
	// Horizontal
	if (event.deltaX > 0) // Left
		direction = layout == CBLayoutRight ? 1 : 0;
	else if (event.deltaX < 0) // Right
		direction = layout == CBLayoutRight ? 0 : 1;
	// Change page
	if (direction == 0)
		[self pageUp:self];
	else
		[self pageDown:self];
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
	[page1 beginContentAccess];
	if (layout != CBLayoutSingle && page1.portrait) // Two Page
	{
		CBPage * page2 = [delegate pageAtIndex:(cp+1)];
		[page2 beginContentAccess];
		if (page2 && page2.portrait)
		{
			[self setPageOne:page1 two:page2];
		}
		else
		{
			[self setPage:page1];
		}
		[page2 endContentAccess];
	}
	else
	{
		[self setPage:page1];
	}
	[page1 endContentAccess];
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
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue
						 forKey:kCATransactionDisableActions];
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
		[CATransaction commit];
	}
}

- (void)setPage:(CBPage*)page
{
	[self setPage:page inSet:currentLayerSet];
}

- (void)setPage:(CBPage*)page inSet:(unsigned char)index
{
	if (index > 2) return;
	[page beginContentAccess];
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
	CGFloat width = pageRect.size.width/2;
	cls->left.bounds = CGRectMake(0, 0, width, pageRect.size.height);
	cls->right.bounds = CGRectMake(0, 0, width, pageRect.size.height);
	cls->left.contents = nil;
	cls->right.contents = nil;
	// Pages
	[cls->page1 endContentAccess];
	[cls->page2 endContentAccess];
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
	[page1 beginContentAccess];
	[page2 beginContentAccess];
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
	[cls->page1 endContentAccess];
	[cls->page2 endContentAccess];
	[cls->page1 release];
	[cls->page2 release];
	cls->page1 = [page1 retain];
	cls->page2 = [page2 retain];
	[self zoomReset];
	[CATransaction commit];
}

// Scrolling & Zooming
- (CGRect)scrollBounds
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
	return scrollBounds;
}

- (void)scrollToPoint:(CGPoint)point
{
	scrollPosition = CBClampPointToRect(point, [self scrollBounds]);
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
	[self autoScrollRebuild];
}

- (void)zoomReset
{
	if (!scrollLayer)
		return;
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

static const CGFloat autoScrollFactor = 0.8;

- (void)autoScrollRebuild
{
	CGRect scrollBounds = [self scrollBounds];
	CGSize scrollSize = scrollLayer.bounds.size;
	NSInteger width, height;
	CGFloat stepWidth, stepHeight;
	// Find out how many steps in each direction
	if (scrollBounds.size.height <= 0)
	{
		height = 1;
		stepHeight = 0;
	}
	else
	{
		height = 1+ceil(scrollBounds.size.height/(scrollSize.height*autoScrollFactor));
		stepHeight = scrollBounds.size.height/(height-1);
	}
	if (scrollBounds.size.width <= 0)
	{
		// Two column content should scroll from top to bottom twice if scrolling
		// is even needed
		if (layout != CBLayoutSingle && height > 1)
			width = 2;
		else
			width = 1;
		stepWidth = 0;
	}
	else
	{
		width = 1+ceil(scrollBounds.size.width/(scrollSize.width*autoScrollFactor));
		stepWidth = scrollBounds.size.width/(width-1);
	}
	// Build the autoScrollPoints array
	[autoScrollPoints removeAllObjects];
	if (layout == CBLayoutRight)
	{
		// right-to-left with minor top-to-bottom
		for (NSInteger i = width-1; i >= 0; i--)
		{
			for (NSInteger j = height-1; j >= 0; j--)
			{
				NSPoint p = NSMakePoint(scrollBounds.origin.x+stepWidth*i,
										scrollBounds.origin.y+stepHeight*j);
				[autoScrollPoints addObject:[NSValue valueWithPoint:p]];
			}
		}
	}
	else
	{
		// left-to-right with minor top-to-bottom
		for (NSInteger i = 0; i < width; i++)
		{
			for (NSInteger j = height-1; j >= 0; j--)
			{
				NSPoint p = NSMakePoint(scrollBounds.origin.x+stepWidth*i,
										scrollBounds.origin.y+stepHeight*j);
				[autoScrollPoints addObject:[NSValue valueWithPoint:p]];
			}
		}
	}
	autoScrollIndex = 0;
}

- (void)autoScrollNext
{
	NSUInteger idx = autoScrollIndex;
	NSPoint point = [[autoScrollPoints objectAtIndex:idx] pointValue];
	CGFloat dist = sqrt(pow(point.x-scrollPosition.x, 2) + pow(point.y-scrollPosition.y, 2));
	if (dist > 1) // idx invalid, search new one
	{
		for (NSUInteger i = 0; i < [autoScrollPoints count]; i++)
		{
			NSPoint p = [[autoScrollPoints objectAtIndex:i] pointValue];
			CGFloat d = sqrt(pow(p.x-scrollPosition.x, 2) + pow(p.y-scrollPosition.y, 2));
			if (d < dist)
			{
				dist = d;
				idx = i;
			}
		}
	}
	if (idx+1 >= [autoScrollPoints count])
	{
		// Next page
		[self pageDown:self];
	}
	else
	{
		// Next point
		autoScrollIndex = idx+1;
		NSPoint p = [[autoScrollPoints objectAtIndex:autoScrollIndex] pointValue];
		[self scrollToPoint:NSPointToCGPoint(p)];
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
