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

@class CIFilter;

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
	// Filters
	CIFilter * gammaFilter;
	// View Transformation State
	CGFloat zoom;
	CGPoint position;
}

- (id)initWithFrame:(NSRect)frameRect;

@property (nonatomic,retain) CBComicModel * model;

@property (nonatomic,assign) CGFloat gammaPower;

- (CGFloat)zoomBy:(CGFloat)factor;
- (CGFloat)zoomBy:(CGFloat)factor withCenter:(CGPoint)center;
- (CGPoint)moveToLayer:(CGPoint)newPos;
- (CGPoint)moveByLayer:(CGPoint)offset;
- (CGPoint)moveByWindow:(CGPoint)offset;
- (CGPoint)moveByRelative:(CGPoint)offset;
- (void)nextPage;
- (void)previousPage;

@property (nonatomic,assign) CGFloat zoom;
@property (nonatomic,assign) CGPoint position;
@property (nonatomic,readonly) CGPoint focusPoint;

- (void)updatePageFromModel;
- (void)updatePageToModel;
- (void)updateView;
- (void)updateViewTransform;

- (NSInteger)currentPageIndex;

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
- (void)magnifyWithEvent:(NSEvent *)event;

- (void)hideMouseCursor;

- (IBAction)setLayoutSingle:(id)sender;
- (IBAction)setLayoutDouble:(id)sender;
- (IBAction)setLeftToRight:(id)sender;
- (IBAction)setRightToLeft:(id)sender;
- (IBAction)shiftPages:(id)sender;

- (void)relayout;

@end
