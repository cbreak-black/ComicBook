//
//  CBComicListController.h
//  ComicBook
//
//  Created by cbreak on 2013.03.24.
//  Copyright (c) 2013 the-color-black.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CBComicModel;

@interface CBComicListController : NSWindowController
{
	CBComicModel * model;
	IBOutlet NSArrayController * frameController;
}

- (id)init;

@property (nonatomic,retain) CBComicModel * model;

@end
