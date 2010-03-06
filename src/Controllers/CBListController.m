//
//  CBListController.m
//  ComicBook
//
//  Created by cbreak on 02.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBListController.h"

#import "CBDocument.h"


@implementation CBListController

- (id)init
{
	self = [super initWithWindowNibName:@"CBList"];
	if (self)
	{
		[self setShouldCascadeWindows:NO];
	}
	return self;
}

- (NSString*)windowFrameAutosaveName
{
	return @"ListPanel";
}

- (void)windowDidLoad
{
	[(NSPanel*)[self window] setBecomesKeyOnlyIfNeeded:YES];
}

// Document updated
- (void)documentUpdated
{
	[tableView reloadData];
}

// TableView DataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [(CBDocument*)[self document] pageCount];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	CBDocument * doc = (CBDocument*)[self document];
	if (doc)
	{
		NSParameterAssert(rowIndex >= 0 && rowIndex < [doc pageCount]);
		if ([[aTableColumn identifier] isEqual:@"path"])
		{
			NSString * path = [[doc getPage:rowIndex] path];
			return [path stringByReplacingOccurrencesOfString:[[doc baseURL] path] withString:@""];
		}
	}
	return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSInteger selectedRow = [tableView selectedRow];
	if (selectedRow >= 0)
	{
		[[self document] selectPage:selectedRow];
	}
}

@end
