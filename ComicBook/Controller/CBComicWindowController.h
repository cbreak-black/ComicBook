//
//  CBComicWindowController.h
//  ComicBook
//
//  Created by cbreak on 2012.12.23.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CBComicView;
@class CBComicModel;

/*!
 \brief A controller for handling CBComicWindows, interfacing between model and view
 */
@interface CBComicWindowController : NSWindowController
{
	IBOutlet CBComicView * comicView;
	IBOutlet NSWindow * loadingSheet;
	IBOutlet NSProgressIndicator * loadingIndicator;
	CBComicModel * model;
}

- (id)init;

@property (nonatomic,retain) CBComicModel * model;

- (void)startLoading;
- (void)stopLoading;

@end
