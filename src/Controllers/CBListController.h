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
	NSTimer * closeTimer;
}

// Designated Initializer
- (id)init;

// TableView DataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

// Selection
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

// Updaters
- (void)updateTableSelection;
- (void)updateTableData;

// Animating
- (BOOL)isShown;
- (void)animateShow:(id)sender;
- (void)animateHide:(id)sender;

@end
