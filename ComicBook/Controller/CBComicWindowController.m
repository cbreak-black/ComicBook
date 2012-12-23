//
//  CBComicWindowController.m
//  ComicBook
//
//  Created by cbreak on 2012.12.23.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBComicWindowController.h"

@implementation CBComicWindowController

- (id)init
{
	if ([super initWithWindowNibName:@"CBComicWindow"])
	{
		[self setShouldCloseDocument:YES];
	}
	return self;
}

- (void)windowDidLoad
{
	[super windowDidLoad];
}

@end
