//
//  CBPageController.m
//  ComicBook
//
//  Created by cbreak on 02.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBPageController.h"

#import "CBDocument.h"
#import "CBPage.h"

@implementation CBPageController

- (id)init
{
	self = [super initWithWindowNibName:@"CBPage"];
	if (self)
	{
		[self setShouldCloseDocument:YES];
		[self setShouldCascadeWindows:NO];
	}
	return self;
}

- (NSString*)windowFrameAutosaveName
{
	return @"PageWindow";
}

- (void)windowDidLoad
{
	[self pageChanged];
}

- (void)pageChanged
{
	CBPage * page = [[self document] getCurrentPage];
}

@end
