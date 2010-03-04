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
@class CBPage;

@interface CBDocument : NSDocument
{
	CBListController * listController;
	CBPageController * pageController;

	NSURL * baseURL;

	NSMutableArray * pages;
}

// Adds URLs to the pages array
- (void)addDirectoryURL:(NSURL *)url;
- (void)addFileURL:(NSURL *)url;

// Page access
- (NSInteger)pageCount;
- (CBPage *)getPage:(NSInteger)number;

@property (retain) CBListController * listController;
@property (retain) CBPageController * pageController;
@property (retain, readonly) NSURL * baseURL;

@end
