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
#import "CBCAView.h"

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

- (void)setDocument:(NSDocument *)document
{
	[[self document] removeObserver:self forKeyPath:@"currentPage"];
	[super setDocument:document];
	[[self document] addObserver:self forKeyPath:@"currentPage" options:NULL context:NULL];
}

- (void)windowDidLoad
{
	[self pageChanged];
}

- (void)pageChanged
{
	CBDocument * doc = [self document];
	NSImage * img = [[doc pageAtIndex:[doc currentPage]] image];
	[caView setImage:img];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"currentPage"])
	{
		[self pageChanged];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
