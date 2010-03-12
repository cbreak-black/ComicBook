//
//  CBCALayoutManager.h
//  ComicBook
//
//  Created by cbreak on 12.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>

@interface CBCALayoutManager : NSObject
{
}

- (CGSize)preferredSizeOfLayer:(CALayer *)layer;
- (void)invalidateLayoutOfLayer:(CALayer *)layer;
- (void)layoutSublayersOfLayer:(CALayer *)layer;

@end
