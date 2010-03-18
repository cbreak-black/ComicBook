//
//  CBPage.h
//  ComicBook
//
//  Created by cbreak on 04.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>


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

// Factories
+ (NSArray*)pagesFromURL:(NSURL*)url;
+ (NSArray*)pagesFromDirectoryURL:(NSURL*)url;
+ (NSArray*)pagesFromFileURL:(NSURL*)url;

@end
