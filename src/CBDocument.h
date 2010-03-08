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
	NSUInteger currentPage;
}

// Adds URLs to the pages array
- (void)addDirectoryURL:(NSURL *)url;
- (void)addFileURL:(NSURL *)url;

// Page access (KVC Compliant)
- (NSInteger)countOfPages;
- (CBPage *)pageAtIndex:(NSUInteger)number;
- (CBPage *)objectInPagesAtIndex:(NSUInteger)number; // KVC version of above
- (void)getPages:(CBPage **)buffer range:(NSRange)inRange;

- (void)advancePage:(NSInteger)offset;
@property (assign) NSUInteger currentPage;

@property (retain) CBListController * listController;
@property (retain) CBPageController * pageController;
@property (retain, readonly) NSURL * baseURL;

@end
