//
//  CBCAView.h
//  ComicBook
//
//  Created by cbreak on 09.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>

@protocol CBInputDelegate;
@class CBPage;

// Settings constants
extern NSString * kCBLayoutKey;
extern NSString * kCBLayoutSingle;
extern NSString * kCBLayoutLeft;
extern NSString * kCBLayoutRight;

// Scale
extern NSString * kCBScaleKey;
extern NSString * kCBScaleOriginal;
extern NSString * kCBScaleWidth;
extern NSString * kCBScaleFull;

// Layout Enums
typedef enum {
	CBLayoutSingle,
	CBLayoutLeft,
	CBLayoutRight,
} CBLayout;

// Scale Enums
typedef enum {
	CBScaleOriginal,
	CBScaleWidth,
	CBScaleFull,
} CBScale;

typedef struct
{
	CBPage * page1;
	CBPage * page2;
	CALayer * container;
	CALayer * left;
	CALayer * right;
}
CBCAViewLayerSet;

@interface CBCAView : NSView
{
	CALayer * backgroundLayer;
	CAScrollLayer * scrollLayer;
	CBCAViewLayerSet layers[3];
	unsigned int currentLayerSet;

	CBLayout layout;
	CBScale scale;

	CGPoint scrollPosition;
	CGFloat zoomFactor;

	id<CBInputDelegate> delegate;
}

- (void)dealloc;

// Initialisation
- (void)awakeFromNib;

// Events
- (BOOL)acceptsFirstResponder;
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
- (void)defaultsChanged:(NSNotification *)notification;
@property (assign) id<CBInputDelegate> delegate;

// Mouse
- (void)scrollWheel:(NSEvent *)event;
- (void)mouseDown:(NSEvent *)event;
- (void)mouseDragged:(NSEvent *)event;
- (void)mouseUp:(NSEvent *)event;
- (void)rightMouseDown:(NSEvent *)event;
- (void)rightMouseDragged:(NSEvent *)event;
- (void)rightMouseUp:(NSEvent *)event;

// Touch
- (void)magnifyWithEvent:(NSEvent *)event;
- (void)rotateWithEvent:(NSEvent *)event;
- (void)swipeWithEvent:(NSEvent *)event;

// Image display
- (void)pageChanged;
- (void)setPage:(CBPage*)page;
- (void)setPage:(CBPage*)page inSet:(unsigned char)index;
- (void)setPageOne:(CBPage*)page1 two:(CBPage*)page2;
- (void)setPageOne:(CBPage*)page1 two:(CBPage*)page2 inSet:(unsigned char)index;

// Scrolling & Zooming
- (void)scrollToPoint:(CGPoint)point;
- (void)scrollByOffsetX:(float)x Y:(float)y;
- (void)zoomIn;
- (void)zoomOut;
- (void)zoomTo:(float)scaleFactor;
- (void)zoomReset;

// Full Screen
- (IBAction)toggleFullscreen:(id)sender;
- (BOOL)enterFullScreen;
- (void)exitFullScreen;

@end
