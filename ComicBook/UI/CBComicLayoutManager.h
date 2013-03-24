//
//  CBComicLayoutManager.h
//  ComicBook
//
//  Created by cbreak on 2013.01.09.
//  Copyright (c) 2013 the-color-black.net. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Quartz/Quartz.h>

#import "CBConstants.h"

@class CBRangeBuffer;

@interface CBComicLayoutManager : NSObject
{
	CBRangeBuffer * pages;
	NSInteger anchorPageIndex;
	// Layout Settings
	CBComicLayoutMode layoutMode;
	CGFloat padding;
	// Meta Infos
	CGFloat verticalTop;
	CGFloat verticalBottom;
}

- (id)initWithPages:(CBRangeBuffer*)pageBuffer;

@property (nonatomic,assign) NSInteger anchorPageIndex;
@property (nonatomic,assign) CBComicLayoutMode layoutMode;
@property (nonatomic,assign) CGFloat padding;

@property (nonatomic,readonly) CGFloat verticalTop;
@property (nonatomic,readonly) CGFloat verticalBottom;

- (void)layoutPages;

// Layout Manager
- (void)layoutSublayersOfLayer:(CALayer *)layer;

@end
