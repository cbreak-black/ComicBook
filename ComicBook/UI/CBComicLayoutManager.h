//
//  CBComicLayoutManager.h
//  ComicBook
//
//  Created by cbreak on 2013.01.09.
//  Copyright (c) 2013 the-color-black.net. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Quartz/Quartz.h>

@class CBRangeBuffer;

typedef enum {
	kCBComicLayoutLeftToRight,
	kCBComicLayoutRightToLeft,
	kCBComicLayoutSingle
} CBComicLayoutMode;

@interface CBComicLayoutManager : NSObject
{
	CBRangeBuffer * pages;
	NSInteger anchorPageIndex;
	// Layout Settings
	CBComicLayoutMode layoutMode;
	// Meta Infos
	CGFloat verticalTop;
	CGFloat verticalBottom;
}

- (id)initWithPages:(CBRangeBuffer*)pageBuffer;

@property (nonatomic,assign) NSInteger anchorPageIndex;
@property (nonatomic,assign) CBComicLayoutMode layoutMode;

@property (nonatomic,readonly) CGFloat verticalTop;
@property (nonatomic,readonly) CGFloat verticalBottom;

// Layout Manager
- (void)layoutSublayersOfLayer:(CALayer *)layer;

@end
