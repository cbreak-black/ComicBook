//
//  CBApplicationDelegate.m
//  ComicBook
//
//  Created by cbreak on 2012.12.22.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBApplicationDelegate.h"

#import "CBDocumentController.h"

@implementation CBApplicationDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	controller = [[CBDocumentController alloc] init];
}

@end
