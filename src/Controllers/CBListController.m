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
	return self;
}

// Document updated
- (void)documentUpdated
{
	[tableView reloadData];
}

// TableView DataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[(CBDocument*)[self document] pages] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSArray * pages = [(CBDocument*)[self document] pages];
	NSParameterAssert(rowIndex >= 0 && rowIndex < [pages count]);
	if ([[aTableColumn identifier] isEqual:@"path"])
	{
		return [pages objectAtIndex:rowIndex];
	}
	return nil;
}

@end
