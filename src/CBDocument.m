//
//  CBDocument.m
//  ComicBook
//
//  Created by cbreak on 01.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBDocument.h"

#import "Controllers/CBListController.h"
#import "Controllers/CBPageController.h"

@implementation CBDocument

- (id)init
{
    self = [super init];
    if (self)
	{
    }
    return self;
}

- (void)dealloc
{
	[listController release];
	[pageController release];
	[super dealloc];
}

- (void)makeWindowControllers
{
	CBListController * lc = [[CBListController alloc] init];
	CBPageController * pc = [[CBPageController alloc] init];
	[self setListController:lc];
	[self setPageController:pc];
	[self addWindowController:lc];
	[self addWindowController:pc];
	[lc release];
	[pc release];
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    if ( outError != NULL )
	{
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	//    if ( outError != NULL )
	//{
	//	*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	//}
    return YES;
}

@synthesize listController;
@synthesize pageController;

@end
