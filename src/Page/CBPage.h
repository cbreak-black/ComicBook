//
//  CBPage.h
//  ComicBook
//
//  Created by cbreak on 04.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// An abstract page, a single image of a comic

@interface CBPage : NSObject <NSDiscardableContent>
{
	NSUInteger number;
	NSUInteger accessCounter;
	NSImage * image;
}

// To query image
@property (retain) NSImage * image;

// To be implemented by subclasses
@property (retain, readonly) NSString * path; // Return the image path
- (BOOL)loadImage; // Load the image, called from image getter and beginContentAccess

// To query properties
@property (readonly, assign, getter=isPortrait) BOOL portrait;
@property (readonly, assign, getter=isLandscape) BOOL landscape;
@property (readonly, assign) CGFloat aspect;
@property (readonly, assign) NSSize size;
@property (assign) NSUInteger number;

// NSDiscardableContent
- (BOOL)beginContentAccess;
- (void)endContentAccess;
- (void)discardContentIfPossible;
- (BOOL)isContentDiscarded;

// Factories (Return arrays of instances of subclasses)
+ (NSArray*)pagesFromURL:(NSURL*)url; // Dispatcher
+ (NSArray*)pagesFromDirectoryURL:(NSURL*)url; // File system tree
+ (NSArray*)pagesFromFileURL:(NSURL*)url; // Single file/archive
+ (NSArray*)pagesFromData:(NSData*)data withPath:(NSString*)path; // For archives

@end
