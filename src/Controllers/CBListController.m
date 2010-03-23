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
	[[self document] addObserver:self forKeyPath:@"currentPage" options:0 context:NULL];
	[[self document] addObserver:self forKeyPath:@"pages" options:0 context:NULL];
	[self updateTableData];
	[self updateTableSelection];
}

- (void)updateTableData
{
	[tableView reloadData];
}

- (void)updateTableSelection
{
	NSUInteger currentPage = [[self document] currentPage];
	if (currentPage != selectedRow)
	{
		selectedRow = currentPage;
		[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:currentPage] byExtendingSelection:NO];
		[tableView scrollRowToVisible:currentPage];
	}
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
	NSUInteger newSelectedRow = [tableView selectedRow];
	if (newSelectedRow != selectedRow && newSelectedRow >= 0)
	{
		selectedRow = newSelectedRow;
		[[self document] setCurrentPage:selectedRow];
	}
}

// Changed from the Document
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"currentPage"])
	{
		[self updateTableSelection];
	}
	else if ([keyPath isEqualToString:@"pages"])
	{
		// Can be optimized if needed
		[self updateTableData];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

// Animating
- (void)animateShow:(id)sender
{
	if (closeTimer)
	{
		// Don't close after all
		[closeTimer invalidate];
		[closeTimer release];
		closeTimer = nil;
	}
	[self showWindow:sender];
	[[self window] setAlphaValue:0.0f];
	[[[self window] animator] setAlphaValue:1.0f];
}

- (void)animateHide:(id)sender
{
	[[self window] setAlphaValue:1.0f];
	[[[self window] animator] setAlphaValue:0.0f];
	closeTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0f
												   target:self selector:@selector(closeTimed)
												 userInfo:nil repeats:NO] retain];
}

- (void)closeTimed
{
	[closeTimer release];
	closeTimer = nil;
	[self close];
}

- (BOOL)isShown
{
	// Returns NO even if window is still visible when a close timer is running
	return [[self window] isVisible] && (closeTimer==nil);
}


@end
