//
//  CBPageController.h
//  ComicBook
//
//  Created by cbreak on 02.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CBInputDelegate.h"

@class CBCAView;

@interface CBPageController : NSWindowController <CBInputDelegate>
{
	IBOutlet CBCAView * caView;
}

// Designated Initializer
- (id)init;

// Document notifications
- (void)pageChanged;

// View Delegate
- (void)advancePage:(NSInteger)offset;
- (CBPage *)pageAtIndex:(NSUInteger)number;
- (NSUInteger)currentPage;

@end
