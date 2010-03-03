//
//  CBDocument.h
//  ComicBook
//
//  Created by cbreak on 01.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class CBListController;
@class CBPageController;

@interface CBDocument : NSDocument
{
	CBListController * listController;
	CBPageController * pageController;

	NSMutableArray * pages;
}

// Adds URLs to the pages array
- (void)addDirectoryURL:(NSURL *)url;
- (void)addFileURL:(NSURL *)url;

@property (retain) CBListController * listController;
@property (retain) CBPageController * pageController;
@property (retain, readonly) NSArray * pages;

@end
