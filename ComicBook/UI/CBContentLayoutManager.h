//
//  CBContentLayoutManager.h
//  ComicBook
//
//  Created by cbreak on 2013.01.09.
//  Copyright (c) 2013 the-color-black.net. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Quartz/Quartz.h>

@interface CBContentLayoutManager : NSObject
{
	CGFloat contentScale;
}

- (id)init;

- (void)layoutSublayersOfLayer:(CALayer *)layer;

@property (atomic,assign) CGFloat contentScale;

@end
