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

- (void)setDocument:(NSDocument *)document
{
	[[self document] removeObserver:self forKeyPath:@"currentPage"];
	[[self document] removeObserver:self forKeyPath:@"pages"];
	[super setDocument:document];
	[[self document] addObserver:self forKeyPath:@"currentPage" options:NULL context:NULL];
	[[self document] addObserver:self forKeyPath:@"pages" options:NULL context:NULL];
}

// TableView DataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [(CBDocument*)[self document] countOfPages];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	CBDocument * doc = (CBDocument*)[self document];
	if (doc)
	{
		NSParameterAssert(rowIndex >= 0 && rowIndex < [doc countOfPages]);
		if ([[aTableColumn identifier] isEqual:@"path"])
		{
			NSString * path = [[doc pageAtIndex:rowIndex] path];
			return [path stringByReplacingOccurrencesOfString:[[doc baseURL] path] withString:@""];
		}
	}
	return nil;
}

// Selection
// Changed from the GUI
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSInteger selectedRow = [tableView selectedRow];
	if (selectedRow >= 0)
	{
		[[self document] setCurrentPage:selectedRow];
	}
}

// Changed from the Document
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"currentPage"])
	{
		NSIndexSet * selectedRows = [tableView selectedRowIndexes];
		NSUInteger currentPage = [[self document] currentPage];
		if (![selectedRows containsIndex:currentPage])
		{
			[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:currentPage] byExtendingSelection:NO];
		}
	}
	else if ([keyPath isEqualToString:@"pages"])
	{
		// Can be optimized if needed
		[tableView reloadData];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
