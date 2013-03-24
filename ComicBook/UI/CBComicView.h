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

- (void)zoomBy:(CGFloat)factor;
- (void)moveBy:(CGPoint)offset;
- (void)moveByRelative:(CGPoint)relativeOffset;
- (void)nextPage;
- (void)previousPage;

@property (nonatomic,assign) CGFloat zoom;
@property (nonatomic,assign) CGPoint position;

- (void)updatePageFromModel;
- (void)updatePageToModel;
- (void)updateView;
- (void)clampViewTransformState;
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

- (IBAction)setLayoutLeftToRight:(id)sender;
- (IBAction)setLayoutRightToLeft:(id)sender;
- (IBAction)setLayoutSingle:(id)sender;

@end
