//
//  CBComicView.h
//  ComicBook
//
//  Created by cbreak on 2012.12.23.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CBRangeBuffer;
@class CBComicModel;

@class CBContentLayoutManager;
@class CBComicLayoutManager;

/*!
 \brief The view hosting the layers that represent the comic
 */
@interface CBComicView : NSView
{
	CALayer * backgroundLayer;
	CALayer * contentLayer;
	CBRangeBuffer * pages;
	CBComicModel * model;
	// Layout
	CBContentLayoutManager * contentLayoutManager;
	CBComicLayoutManager * comicLayoutManager;
	// View Transformation State
	CGFloat zoom;
	CGPoint position;
}

- (id)initWithFrame:(NSRect)frameRect;

@property (nonatomic,retain) CBComicModel * model;

- (void)zoomBy:(CGFloat)factor;
- (void)moveBy:(CGPoint)offset;

@property (nonatomic,assign) CGFloat zoom;
@property (nonatomic,assign) CGPoint position;

- (void)setNeedsViewTransformUpdate;
- (void)clampViewTransformState;
- (void)updateViewTransform;

- (BOOL)acceptsFirstResponder;
- (BOOL)resignFirstResponder;

- (void)mouseDown:(NSEvent*)event;
- (void)mouseDragged:(NSEvent*)event;
- (void)mouseMoved:(NSEvent*)event;
- (void)mouseUp:(NSEvent*)event;
- (void)scrollWheel:(NSEvent*)event;
- (void)keyDown:(NSEvent*)event;
- (void)keyUp:(NSEvent*)event;
- (void)swipeWithEvent:(NSEvent*)event;

@end
