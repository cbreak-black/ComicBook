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
#import "CBFrame.h"

#import "CBContentLayoutManager.h"
#import "CBComicLayoutManager.h"

#import <QuartzCore/CoreImage.h>

static const NSInteger kCBPageCacheCountFwd = 16;
static const NSInteger kCBPageCacheCountBwd = 8;
static const CGFloat kCBCoarseLineFactor = 32.0;
static const CGFloat kCBKeyboardMoveFactor = 0.75;
static const CGFloat kCBKeyboardZoomFactor = 1.25;
static const CGFloat kCBZoomMin = 0.20;
static const CGFloat kCBZoomMax = 5.00;

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
		// Page Update Blocks
		__unsafe_unretained CBComicView * weakSelf = self;
		pages.exitBlock = ^(id obj, NSInteger idx)
		{
			CBPageLayer * pageLayer = obj;
			[CATransaction begin];
			[CATransaction setAnimationDuration:0.5];
			[pageLayer removeFromSuperlayer];
			CBPageLayer * newPage = [[CBPageLayer alloc] init];
			[weakSelf->pages replaceObjectAtIndex:idx withObject:newPage];
			[CATransaction commit];
		};
		pages.postShift = ^()
		{
			dispatch_sync(dispatch_get_main_queue(), ^()
			{
				[weakSelf relayout];
			});
		};
		pages.enterBlock = ^(id obj, NSInteger idx)
		{
			CBPageLayer * pageLayer = obj;
			CBFrame * frame = [[weakSelf model] frameAtIndex:idx];
			if (pageLayer.comicFrame != frame)
			{
				// Load frame in current queue, assign in main thread
				NSImage * image = [frame image];
				[CATransaction begin];
				[CATransaction setAnimationDuration:0.5];
				if (!pageLayer.superlayer)
					[weakSelf->contentLayer addSublayer:pageLayer];
				[pageLayer setImage:image forFrame:frame];
				[CATransaction commit];
			}
		};
		pages.postEnter = pages.postShift;
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
	contentLayer.actions = @{@"sublayers": [NSNull null]};
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
		[model removeObserver:self forKeyPath:@"frames"];
		[model removeObserver:self forKeyPath:@"currentFrameIdx"];
		[model removeObserver:self forKeyPath:@"layoutMode"];
	}
	model = model_;
	if (model != nil)
	{
		[model addObserver:self forKeyPath:@"frames"
				   options:0 context:0];
		[model addObserver:self forKeyPath:@"currentFrameIdx"
				   options:NSKeyValueObservingOptionInitial context:0];
		[model addObserver:self forKeyPath:@"layoutMode"
				   options:NSKeyValueObservingOptionInitial context:0];
	}
}

@synthesize model;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
						change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"frames"])
	{
		NSIndexSet * changed = [change objectForKey:NSKeyValueChangeIndexesKey];
		NSUInteger currentFrameIdx = model.currentFrameIdx;
		[pages enumerateObjectsInRange:CBRangeMake([changed firstIndex], [changed lastIndex]+1)
					   usingBlockAsync:pages.enterBlock
							completion:^()
		 {
			 dispatch_async(dispatch_get_main_queue(), ^()
			 {
				 if ([changed containsIndex:currentFrameIdx])
					 [self updatePageFromModel];
			 });
		 }];
	}
	else if ([keyPath isEqualToString:@"currentFrameIdx"])
	{
		[self updatePageFromModel];
	}
	else if ([keyPath isEqualToString:@"layoutMode"])
	{
		comicLayoutManager.layoutMode = model.layoutMode;
		[self relayout];
	}
}

- (CGFloat)zoomBy:(CGFloat)factor
{
	CGSize bgSize = backgroundLayer.bounds.size;
	return [self zoomBy:factor withCenter:CGPointMake(bgSize.width/2, bgSize.height/2)];
}

- (CGFloat)zoomBy:(CGFloat)factor withCenter:(CGPoint)center
{
	// Calculate effective zoom factor
	CGFloat newZoom = zoom*factor;
	if      (newZoom < kCBZoomMin) factor = kCBZoomMin/zoom;
	else if (newZoom > kCBZoomMax) factor = kCBZoomMax/zoom;
	zoom *= factor;
	// Correct to keep the center where it is
	CGSize bgSize = backgroundLayer.bounds.size;
	CGFloat correctionFactor = (1.0-factor);
	CGPoint delta = {
		(center.x-bgSize.width/2)*correctionFactor,
		(center.y-bgSize.height)*correctionFactor
	};
	[self moveByWindow:delta]; // calls updateView
	return factor;
}

- (CGPoint)moveToLayer:(CGPoint)newPos
{
	// Limits
	CGSize contentSize = contentLayer.bounds.size;
	CGFloat hLimit = fabs(contentSize.width/2*(1.0-1.0/zoom));
	CGFloat vLimitTop = -comicLayoutManager.verticalTop;
	CGFloat vLimitBottom = -comicLayoutManager.verticalBottom-contentSize.height/zoom;
	if (vLimitBottom < vLimitTop)
	{
		CGFloat t = vLimitBottom;
		vLimitBottom = vLimitTop;
		vLimitTop = t;
	}
	// Calculate effective position
	if      (newPos.x < -hLimit) newPos.x = -hLimit;
	else if (newPos.x > +hLimit) newPos.x = +hLimit;
	if      (newPos.y < vLimitTop) newPos.y = vLimitTop;
	else if (newPos.y > vLimitBottom) newPos.y = vLimitBottom;
	position = newPos;
	[self updateView];
	return newPos;
}

- (CGPoint)moveByLayer:(CGPoint)offset
{
	CGPoint newPos = CGPointMake(position.x + offset.x, position.y + offset.y);
	CGPoint effective = [self moveToLayer:newPos];
	return CGPointMake(newPos.x-effective.x, newPos.y-effective.y);
}

- (CGPoint)moveByWindow:(CGPoint)offset
{
	CGFloat contentScale = contentLayoutManager.contentScale*zoom;
	CGPoint effective = [self moveByLayer:CGPointMake(offset.x/contentScale, offset.y/contentScale)];
	return CGPointMake(effective.x*contentScale, effective.y*contentScale);
}

- (CGPoint)moveByRelative:(CGPoint)offset
{
	CGSize contentSize = contentLayer.bounds.size;
	CGPoint effective = [self moveByLayer:CGPointMake(offset.x*contentSize.width, offset.y*contentSize.height)];
	return CGPointMake(effective.x/contentSize.width, effective.y/contentSize.height);
}

- (void)nextPage
{
	NSInteger currentIdx = [self currentPageIndex];
	CBPageLayer * currentPage = [pages objectAtIndex:currentIdx];
	CBPageLayer * nextPage = [pages objectAtIndex:currentIdx+1];
	if (currentPage.isLaidOut && nextPage.isLaidOut)
	{
		if (currentPage.position.y == nextPage.position.y)
			[model shiftCurrentFrameIdx:+2];
		else
			[model shiftCurrentFrameIdx:+1];
	}
}

- (void)previousPage
{
	NSInteger currentIdx = [self currentPageIndex];
	CBPageLayer * currentPage = [pages objectAtIndex:currentIdx];
	CBPageLayer * previousPage = [pages objectAtIndex:currentIdx-1];
	if (currentPage.isLaidOut && previousPage.isLaidOut)
	{
		if (currentPage.position.y == previousPage.position.y)
			[model shiftCurrentFrameIdx:-2];
		else
			[model shiftCurrentFrameIdx:-1];
	}
}

- (void)setZoom:(CGFloat)zoom_
{
	zoom = zoom_;
	[self updateView];
}

- (void)setPosition:(CGPoint)position_
{
	position = position_;
	[self updateView];
}

@synthesize zoom;
@synthesize position;

- (void)updatePageFromModel
{
	NSInteger currentPage = model.currentFrameIdx;
	comicLayoutManager.anchorPageIndex = currentPage;
	if (currentPage != [self currentPageIndex])
	{
		[pages asyncShiftTo:(currentPage-kCBPageCacheCountBwd) completion:^()
		{
			dispatch_async(dispatch_get_main_queue(), ^()
			{
				// TODO: Jump to proper page entry point
				CBPageLayer * page = [pages objectAtIndex:currentPage];
				if (page.isLaidOut)
					self.position = CGPointMake(0, -page.position.y);
			});
		}];
	}
	else
	{
		[pages asyncShiftTo:(currentPage-kCBPageCacheCountBwd)];
	}
}

- (void)updatePageToModel
{
	// Update pages asynchronously
	NSInteger currentPage = [self currentPageIndex];
	if (model.currentFrameIdx != currentPage && currentPage >= 0)
		model.currentFrameIdx = currentPage;
}

- (void)updateView
{
	[self updateViewTransform];
	[self updatePageToModel];
}

- (void)updateViewTransform
{
	CATransform3D scale = CATransform3DMakeScale(zoom, zoom, 1);
	CATransform3D translate = CATransform3DMakeTranslation(position.x, position.y, 0);
	CATransform3D viewTransform = CATransform3DConcat(translate, scale);
	contentLayer.sublayerTransform = viewTransform;
}

- (NSInteger)currentPageIndex
{
	// Find closest page
	__block NSInteger closestPageIdx = -1;
	__block CGFloat closestPageDistance = CGFLOAT_MAX;
	[pages enumerateObjectsUsingBlock:^(id obj, NSInteger idx)
	 {
		 CBPageLayer * page = obj;
		 if (!page.isLaidOut || !page.isValid)
			 return;
		 CGPoint pagePos = page.position;
		 CGFloat pageDistance = fabs(-position.y - pagePos.y);
		 if (closestPageDistance > pageDistance)
		 {
			 closestPageDistance = pageDistance;
			 closestPageIdx = idx;
		 }
	 }];
	return closestPageIdx;
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
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	[self moveByWindow:CGPointMake([event deltaX], -[event deltaY])];
	[CATransaction commit];
}

- (void)mouseMoved:(NSEvent*)event
{
}

- (void)mouseUp:(NSEvent*)event
{
}

- (void)scrollWheel:(NSEvent*)event
{
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	if ([event modifierFlags] & NSShiftKeyMask)
	{
		// Scale Factor
		CGFloat offset = [event scrollingDeltaX]-[event scrollingDeltaY];
		if (![event hasPreciseScrollingDeltas])
			offset *= kCBCoarseLineFactor;
		CGFloat factor = pow(0.999, offset);
		// Position
		NSPoint viewPos = [self convertPoint:event.locationInWindow fromView:nil];
		NSPoint layerPos = [self convertPointToBacking:viewPos];
		[self zoomBy:factor withCenter:layerPos];
	}
	else
	{
		if ([event hasPreciseScrollingDeltas])
			[self moveByWindow:CGPointMake(+[event scrollingDeltaX],
										   -[event scrollingDeltaY])];
		else
			[self moveByWindow:CGPointMake(+[event scrollingDeltaX]*kCBCoarseLineFactor,
										   -[event scrollingDeltaY]*kCBCoarseLineFactor)];
	}
	[CATransaction commit];
}

- (void)keyDown:(NSEvent*)event
{
	[CATransaction begin];
	[CATransaction setAnimationDuration:0.5];
	NSString * characters = [event charactersIgnoringModifiers];
	switch ([characters characterAtIndex:0])
	{
		case ' ':
			break;
		case '+':
			[self zoomBy:kCBKeyboardZoomFactor];
			break;
		case '-':
			[self zoomBy:1.0/kCBKeyboardZoomFactor];
			break;
		case NSUpArrowFunctionKey:
			[self moveByRelative:CGPointMake(0, -kCBKeyboardMoveFactor)];
			break;
		case NSDownArrowFunctionKey:
			[self moveByRelative:CGPointMake(0, +kCBKeyboardMoveFactor)];
			break;
		case NSLeftArrowFunctionKey:
			[self moveByRelative:CGPointMake(+kCBKeyboardMoveFactor, 0)];
			break;
		case NSRightArrowFunctionKey:
			[self moveByRelative:CGPointMake(-kCBKeyboardMoveFactor, 0)];
			break;
		case NSPageUpFunctionKey:
			[self previousPage];
			break;
		case NSPageDownFunctionKey:
			[self nextPage];
			break;
		default:
			NSLog(@"Unhandled Key Event: %@", event);
	}
	[CATransaction commit];
}

- (void)keyUp:(NSEvent*)event
{
}

- (void)swipeWithEvent:(NSEvent*)event
{
	CBComicLayoutMode mode = comicLayoutManager.layoutMode;
	if (event.deltaY < 0)
		[self nextPage];
	else if (event.deltaY > 0)
		[self previousPage];
	else
	{
		if (mode == kCBComicLayoutLeftToRight)
		{
			if (event.deltaX < 0)
				[self nextPage];
			else if (event.deltaX > 0)
				[self previousPage];
		}
		else
		{
			if (event.deltaX < 0)
				[self previousPage];
			else if (event.deltaX > 0)
				[self nextPage];
		}
	}
}

- (void)magnifyWithEvent:(NSEvent *)event
{
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	NSPoint viewPos = [self convertPoint:event.locationInWindow fromView:nil];
	NSPoint layerPos = [self convertPointToBacking:viewPos];
	[self zoomBy:1.0 + event.magnification withCenter:layerPos];
	[CATransaction commit];
}

- (IBAction)setLayoutLeftToRight:(id)sender
{
	model.layoutMode = kCBComicLayoutLeftToRight;
}

- (IBAction)setLayoutRightToLeft:(id)sender
{
	model.layoutMode = kCBComicLayoutRightToLeft;
}

- (IBAction)setLayoutSingle:(id)sender
{
	model.layoutMode = kCBComicLayoutSingle;
}

- (IBAction)shiftPages:(id)sender
{
	[comicLayoutManager shiftPages];
}

- (void)relayout
{
	[comicLayoutManager layoutPages];
	contentLayoutManager.contentWidth = comicLayoutManager.width;
	[backgroundLayer setNeedsLayout];
}

@end
