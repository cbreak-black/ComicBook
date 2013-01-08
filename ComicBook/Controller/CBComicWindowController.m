//
//  CBComicWindowController.m
//  ComicBook
//
//  Created by cbreak on 2012.12.23.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBComicWindowController.h"

#import "CBComicView.h"

@implementation CBComicWindowController

- (id)init
{
	if (self = [super initWithWindowNibName:@"CBComicWindow"])
	{
		[self setShouldCloseDocument:YES];
	}
	return self;
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	comicView.model = model;
}

- (void)setModel:(CBComicModel *)model_
{
	model = model_;
	if (comicView)
		comicView.model = model;
}

@synthesize model;

@end
