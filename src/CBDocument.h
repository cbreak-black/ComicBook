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
}

@property (retain) CBListController * listController;
@property (retain) CBPageController * pageController;

@end
