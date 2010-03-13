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

@interface CBCAView : NSView
{
	CAScrollLayer * scrollLayer;
	CALayer * containerLayer;
	CALayer * pageLayerLeft;
	CALayer * pageLayerRight;

	CBLayout layout;
	CBScale scale;

	CGPoint scrollPosition;

	NSUInteger pageDisplayCount;

	id<CBInputDelegate> delegate;
}

- (void)dealloc;

// Initialisation
- (void)awakeFromNib;
- (void)loadDefaults:(NSUserDefaults *)ud;

// Events
- (BOOL)acceptsFirstResponder;
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
- (void)defaultsChanged:(NSNotification *)notification;
@property (assign) id<CBInputDelegate> delegate;

// UI / Animation
- (void)configureLayers;

// Image display
- (void)pageChanged;
- (void)setImage:(NSImage*)img;
- (void)setImageLeft:(NSImage*)imgLeft right:(NSImage*)imgRight;

// Scrolling
- (void)scrollToPoint:(CGPoint)point;
- (void)scrollByOffsetX:(float)x Y:(float)y;

// Full Screen
- (IBAction)toggleFullscreen:(id)sender;
- (BOOL)enterFullScreen;
- (void)exitFullScreen;

@end
