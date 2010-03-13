//
//  CBDocumentController.h
//  ComicBook
//
//  Created by cbreak on 05.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Responsible for managing documents and global settings
@interface CBDocumentController : NSDocumentController
{
	NSUserDefaults * defaults;
	BOOL modifying;
}

- (id)init;

- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions;

// Document global settings
@property (assign) BOOL layoutSingle;
@property (assign) BOOL layoutLeft;
@property (assign) BOOL layoutRight;
@property (assign) BOOL scaleOriginal;
@property (assign) BOOL scaleWidth;
@property (assign) BOOL scaleFull;

- (void)defaultsChanged:(NSNotification*)notification;

@end
