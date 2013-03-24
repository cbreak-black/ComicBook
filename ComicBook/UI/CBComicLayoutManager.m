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
		anchorPageIndex = 0;
		layoutMode = kCBComicLayoutRightToLeft;
		paddingVertical = 0.05;
		paddingHorizontal = 0.025;
		verticalBottom = 0.0;
		verticalTop = 0.0;
		width = 2.0 + paddingHorizontal;
	}
	return self;
}

@synthesize anchorPageIndex;

@synthesize layoutMode;
@synthesize paddingVertical;
@synthesize paddingHorizontal;

- (CBPageAlignment)lineStartAlignment
{
	switch (layoutMode)
	{
		case kCBComicLayoutLeftToRight:
			return kCBPageLeft;
		case kCBComicLayoutRightToLeft:
			return kCBPageRight;
		case kCBComicLayoutSingle:
			return kCBPageDouble;
		default:
			return kCBPageUnaligned;
	}
}

- (CBPageAlignment)lineEndAlignment
{
	switch (layoutMode)
	{
		case kCBComicLayoutLeftToRight:
			return kCBPageRight;
		case kCBComicLayoutRightToLeft:
			return kCBPageLeft;
		case kCBComicLayoutSingle:
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

- (CGFloat)offsetForAlignment:(CBPageAlignment)alignment
{
	if (alignment == kCBPageLeft)
		return -paddingHorizontal/2.0;
	else if (alignment == kCBPageRight)
		return +paddingHorizontal/2.0;
	return 0.0;
}

- (void)layoutPages
{
	[CATransaction begin];
	[CATransaction setAnimationDuration:0.5];
	[CATransaction setDisableActions:NO];
	[self configurePages];
	if (layoutMode == kCBComicLayoutSingle)
		[self layoutSingle];
	else
		[self layoutDouble];
	[CATransaction commit];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
	[self layoutPages];
}

- (void)layoutDouble
{
	// Determine initial layout state
	CBPageAlignment layoutAnchorAlignment = [self lineStartAlignment];
	CGFloat layoutAnchorRow = 0.0;
	NSInteger layoutAnchorIdx = anchorPageIndex;
	NSInteger pageIdxStart = pages.startIndex;
	NSInteger pageIdxEnd = pages.endIndex;
	// Find anchor
	if (pageIdxStart == pageIdxEnd) return;
	if (layoutAnchorIdx < pageIdxStart) layoutAnchorIdx = pageIdxStart;
	if (layoutAnchorIdx >= pageIdxEnd) layoutAnchorIdx = pageIdxEnd-1;
	CBPageLayer * anchorLayer = [pages objectAtIndex:layoutAnchorIdx];
	CBPageLayer * anchorLayerPre = [pages objectAtIndex:layoutAnchorIdx-1];
	if (layoutAnchorIdx == 0)
	{
		// First Page is empty
		layoutAnchorAlignment = [self nextAlignment:layoutAnchorAlignment];
	}
	if (anchorLayer.isLaidOut)
	{
		if (anchorLayer.alignment != kCBPageDouble)
			layoutAnchorAlignment = anchorLayer.alignment;
		layoutAnchorRow = anchorLayer.position.y;
	}
	// If the previous page is a single page and the current page is at the end, anchor at the prev
	if (anchorLayerPre.isValid &&
		!anchorLayerPre.isDoublePage && layoutAnchorAlignment == [self lineEndAlignment])
	{
		// Not laid out, but anchor has a previous that is not double page
		layoutAnchorAlignment = [self nextAlignment:layoutAnchorAlignment];
		layoutAnchorIdx -= 1;
	}
	// Forward
	CBPageAlignment pageAlignment = layoutAnchorAlignment;
	CGFloat pageRowBase = layoutAnchorRow;
	CGFloat pageRowHeight = 0.0;
	CGFloat pageWidth = 0.0;
	for (NSInteger i = layoutAnchorIdx; i < pageIdxEnd; ++i)
	{
		CBPageLayer * pageLayer = [pages objectAtIndex:i];
		// Position the Page
		if (pageLayer.isDoublePage)
		{
			// Put the whole page onto a new line
			pageAlignment = kCBPageDouble;
			pageRowBase -= pageRowHeight;
			pageRowHeight = 0.0;
			pageWidth = width;
		}
		else
		{
			pageWidth = 1.0;
		}
		[pageLayer setPosition:CGPointMake([self offsetForAlignment:pageAlignment], pageRowBase)];
		[pageLayer setAlignment:pageAlignment];
		[pageLayer setWidth:pageWidth];
		// Advance line
		pageRowHeight = fmax(pageLayer.bounds.size.height, pageRowHeight);
		pageAlignment = [self nextAlignment:pageAlignment];
		if (pageAlignment == [self lineStartAlignment])
		{
			pageRowBase -= pageRowHeight + paddingVertical;
			pageRowHeight = 0.0;
		}
	}
	verticalBottom = pageRowBase;
	// Backward (this is a pain due to uneven line heights and single between double pages)
	pageRowBase = layoutAnchorRow;
	for (NSInteger i = layoutAnchorIdx-1; i >= pageIdxStart;)
	{
		CBPageLayer * pageLayer0 = [pages objectAtIndex:i];
		// Position the Page
		if (pageLayer0.isDoublePage)
		{
			[pageLayer0 setAlignment:kCBPageDouble];
			[pageLayer0 setWidth:width];
			pageRowBase += pageLayer0.bounds.size.height + paddingVertical;
			[pageLayer0 setPosition:CGPointMake(0, pageRowBase)];
			--i;
		}
		else
		{
			CBPageLayer * pageLayer1 = [pages objectAtIndex:i-1];
			if (pageLayer1 && pageLayer1.isValid) // Valid
			{
				if (pageLayer1.isDoublePage)
				{
					CBPageAlignment alignment = [self lineStartAlignment];
					[pageLayer0 setAlignment:alignment];
					[pageLayer0 setWidth:1.0];
					pageRowBase += pageLayer0.bounds.size.height + paddingVertical;
					[pageLayer0 setPosition:CGPointMake([self offsetForAlignment:alignment], pageRowBase)];
					--i;
				}
				else
				{
					CBPageAlignment alignment0 = [self lineEndAlignment];
					CBPageAlignment alignment1 = [self lineStartAlignment];
					[pageLayer0 setAlignment:alignment0];
					[pageLayer0 setWidth:1.0];
					[pageLayer1 setAlignment:alignment1];
					[pageLayer1 setWidth:1.0];
					pageRowBase += fmax(pageLayer0.bounds.size.height, pageLayer1.bounds.size.height) + paddingVertical;
					[pageLayer0 setPosition:CGPointMake([self offsetForAlignment:alignment0], pageRowBase)];
					[pageLayer1 setPosition:CGPointMake([self offsetForAlignment:alignment1], pageRowBase)];
					i -= 2;
				}
			}
			else
			{
				CBPageAlignment alignment0 = [self lineEndAlignment];
				[pageLayer0 setAlignment:alignment0];
				[pageLayer0 setWidth:1.0];
				pageRowBase += pageLayer0.bounds.size.height + paddingVertical;
				[pageLayer0 setPosition:CGPointMake([self offsetForAlignment:alignment0], pageRowBase)];
				--i;
			}
		}
	}
	verticalTop = pageRowBase;
}

- (void)layoutSingle
{
	// Determine initial layout state
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
		layoutAnchorRow = anchorLayer.position.y;
	}
	// Forward
	CGFloat pageRowBase = layoutAnchorRow;
	for (NSInteger i = layoutAnchorIdx; i < pageIdxEnd; ++i)
	{
		CBPageLayer * pageLayer = [pages objectAtIndex:i];
		[pageLayer setPosition:CGPointMake(0, pageRowBase)];
		[pageLayer setAlignment:kCBPageDouble];
		[pageLayer setWidth:width];
		pageRowBase -= pageLayer.bounds.size.height + paddingVertical;
	}
	verticalBottom = pageRowBase;
	// Backward
	pageRowBase = layoutAnchorRow;
	for (NSInteger i = layoutAnchorIdx-1; i >= pageIdxStart; --i)
	{
		CBPageLayer * pageLayer = [pages objectAtIndex:i];
		[pageLayer setAlignment:kCBPageDouble];
		[pageLayer setWidth:width];
		pageRowBase += pageLayer.bounds.size.height + paddingVertical;
		[pageLayer setPosition:CGPointMake(0, pageRowBase)];
	}
	verticalTop = pageRowBase;
}

- (void)configurePages
{
	CGSize shadowOffset;
	if (layoutMode == kCBComicLayoutLeftToRight)
		shadowOffset = CGSizeMake(paddingHorizontal, -paddingVertical/2);
	else if (layoutMode == kCBComicLayoutRightToLeft)
		shadowOffset = CGSizeMake(-paddingHorizontal, -paddingVertical/2);
	else
		shadowOffset = CGSizeMake(0.0, -paddingVertical/2);
	[pages enumerateObjectsUsingBlock:^(id obj, NSInteger idx)
	{
		CBPageLayer * page = obj;
		page.shadowOffset = shadowOffset;
		page.zPosition = (CGFloat)idx;
	}];
}

@synthesize verticalTop;
@synthesize verticalBottom;
@synthesize width;

@end
