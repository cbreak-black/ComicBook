//
//  CBCAView.h
//  ComicBook
//
//  Created by cbreak on 09.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>

@interface CBCAView : NSView
{
	CALayer * containerLayer;
	CALayer * pageLayerLeft;
	CALayer * pageLayerRight;
}

- (void)dealloc;

// Initialisation
- (void)awakeFromNib;
- (void)configureLayers;

// Image display
- (void)setImage:(NSImage*)img;
- (void)setImageLeft:(NSImage*)imgLeft right:(NSImage*)imgRight;

@end
