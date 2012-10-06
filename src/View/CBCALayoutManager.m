//
//  CBCALayoutManager.m
//  ComicBook
//
//  Created by cbreak on 12.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBCALayoutManager.h"


@implementation CBCALayoutManager

- (CGSize)preferredSizeOfLayer:(CALayer *)layer
{
	return CGSizeMake(0, 0);
}

- (void)invalidateLayoutOfLayer:(CALayer *)layer
{
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
}

@end
