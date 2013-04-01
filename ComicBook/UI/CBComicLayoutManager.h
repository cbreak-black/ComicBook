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
	CBComicDirection direction;
	CGFloat paddingHorizontal;
	CGFloat paddingVertical;
	// Meta Infos
	CGFloat verticalTop;
	CGFloat verticalBottom;
	CGFloat width;
}

- (id)initWithPages:(CBRangeBuffer*)pageBuffer;

@property (nonatomic,assign) NSInteger anchorPageIndex;
@property (nonatomic,assign) CBComicLayoutMode layoutMode;
@property (nonatomic,assign) CBComicDirection direction;
@property (nonatomic,assign) CGFloat paddingVertical;
@property (nonatomic,assign) CGFloat paddingHorizontal;

@property (nonatomic,readonly) CGFloat verticalTop;
@property (nonatomic,readonly) CGFloat verticalBottom;
@property (nonatomic,readonly) CGFloat width;

- (void)shiftPages;
- (void)layoutPages;
- (void)configurePages;

// Layout Manager
- (void)layoutSublayersOfLayer:(CALayer *)layer;

@end
