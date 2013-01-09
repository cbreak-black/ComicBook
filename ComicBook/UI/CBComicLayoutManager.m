//
//  CBComicLayoutManager.m
//  ComicBook
//
//  Created by cbreak on 2013.01.09.
//  Copyright (c) 2013 the-color-black.net. All rights reserved.
//

#import "CBComicLayoutManager.h"

#import "CBRangeBuffer.h"
#import "CBPageLayer.h"

#include <math.h>

@implementation CBComicLayoutManager

- (id)initWithPages:(CBRangeBuffer*)pageBuffer
{
	if (self = [super init])
	{
		pages = pageBuffer;
		anchorPageIdx = 0;
		layoutMode = kCBComicLayoutRightToLeft;
	}
	return self;
}

@synthesize anchorPageIndex;

@synthesize layoutMode;

- (CBPageAlignment)lineStartAlignment
{
	switch (layoutMode)
	{
		case kCBComicLayoutLeftToRight:
			return kCBPageLeft;
		case kCBComicLayoutRightToLeft:
			return kCBPageRight;
		case kCBComicLayoutDouble:
			return kCBPageDouble;
		default:
			return kCBPageUnaligned;
	}
}

- (CBPageAlignment)nextAlignment:(CBPageAlignment)currentAlignment
{
	switch (currentAlignment)
	{
		case kCBPageLeft:
			return kCBPageRight;
		case kCBPageRight:
			return kCBPageLeft;
		default:
			return [self lineStartAlignment];
	}
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
	// Determine initial layout state
	CBPageAlignment layoutAnchorAlignment = [self nextAlignment:[self lineStartAlignment]];
	CGFloat layoutAnchorRow = 0.0;
	NSInteger layoutAnchorIdx = anchorPageIndex;
	NSInteger pageIdxStart = pages.startIndex;
	NSInteger pageIdxEnd = pages.endIndex;
	// Find anchor
	if (pageIdxStart == pageIdxEnd) return;
	if (layoutAnchorIdx < pageIdxStart) layoutAnchorIdx = pageIdxStart;
	if (layoutAnchorIdx >= pageIdxEnd) layoutAnchorIdx = pageIdxEnd-1;
	CBPageLayer * anchorLayer = [pages objectAtIndex:layoutAnchorIdx];
	if (anchorLayer.isLaidOut)
	{
		layoutAnchorAlignment = anchorLayer.alignment;
		layoutAnchorRow = anchorLayer.position.y;
	}
	// Forward
	CBPageAlignment forwardAlignment = layoutAnchorAlignment;
	CGFloat forwardRowBase = layoutAnchorRow;
	CGFloat forwardRowHeight = 0.0;
	for (NSInteger i = layoutAnchorIdx; i < pageIdxEnd; ++i)
	{
		CBPageLayer * pageLayer = [pages objectAtIndex:i];
		// Position the Page
		if (pageLayer.isDoublePage || layoutMode == kCBComicLayoutDouble)
		{
			// Put the whole page onto a new line
			forwardAlignment = kCBPageDouble;
			forwardRowBase -= forwardRowHeight;
			forwardRowHeight = 0.0;
		}
		[pageLayer setPosition:CGPointMake(0, forwardRowBase) withAlignment:forwardAlignment];
		// Advance line
		forwardRowHeight = fmax(pageLayer.bounds.size.height, forwardRowHeight);
		forwardAlignment = [self nextAlignment:forwardAlignment];
		if (forwardAlignment == [self lineStartAlignment])
		{
			forwardRowBase -= forwardRowHeight;
			forwardRowHeight = 0.0;
		}
	}
}

@end
