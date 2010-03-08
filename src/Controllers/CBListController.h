//
//  CBListController.h
//  ComicBook
//
//  Created by cbreak on 02.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CBListController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
{
	IBOutlet NSTableView * tableView;
}

// Designated Initializer
- (id)init;

// TableView DataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

// Selection
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

@end
