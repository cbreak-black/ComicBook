//
//  CBPageLayer.h
//  ComicBook
//
//  Created by cbreak on 2012.12.23.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class CBFrame;

typedef enum {
	kCBPageUnaligned = 0x00,
	kCBPageLeft      = 0x01,
	kCBPageRight     = 0x10,
	kCBPageDouble    = kCBPageLeft | kCBPageRight
} CBPageAlignment;

static const CGFloat kCBPageDoubleThreshold = 1.0;

/*!
 \brief A layer representing an individual single page (or a double page) inside a comic view
 */
@interface CBPageLayer : CALayer
{
	NSImage * image;
	CGFloat aspect;
	CBPageAlignment alignment;
	BOOL isLaidOut;
}

- (id)init;

- (void)setPosition:(CGPoint)position withAlignment:(CBPageAlignment)alignment;

@property (atomic,retain) NSImage * image;
@property (atomic,readonly) CGFloat aspect;
@property (atomic,assign) CBPageAlignment alignment;
@property (atomic,readonly) BOOL isDoublePage; // True if aspect > kCBPageDoubleThreshold
@property (atomic,readonly) BOOL isLaidOut;

@end
