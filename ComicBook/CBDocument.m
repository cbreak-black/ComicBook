//
//  CBDocument.m
//  ComicBook
//
//  Created by cbreak on 2012.12.15.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBDocument.h"

@implementation CBDocument

- (id)init
{
    self = [super init];
    if (self) {
		// Add your subclass-specific initialization here.
    }
    return self;
}

- (NSString *)windowNibName
{
	// Override returning the nib file name of the document
	return @"CBDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	[super windowControllerDidLoadNib:aController];
	// Add any code here that needs to be executed once the windowController has
	// loaded the document's window.
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName
					  error:(NSError **)outError
{
	return YES;
}

-(BOOL)isEntireFileLoaded
{
	return NO;
}

@end
