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

}

// To query image
@property (retain, readonly) NSImage * image;
@property (retain, readonly) NSString * path;

// To query properties
@property (readonly, assign) CGFloat aspect;
@property (readonly, assign) NSSize size;

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
