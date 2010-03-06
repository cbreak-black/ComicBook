//
//  CBPageController.h
//  ComicBook
//
//  Created by cbreak on 02.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CBPageController : NSWindowController <NSTableViewDataSource>
{
}

// Designated Initializer
- (id)init;

// Document notifications
- (void)pageChanged;

@end
