//
//  CBApplicationDelegate.h
//  ComicBook
//
//  Created by cbreak on 2012.12.22.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CBDocumentController;

@interface CBApplicationDelegate : NSObject
{
	CBDocumentController * controller;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification;

@end
