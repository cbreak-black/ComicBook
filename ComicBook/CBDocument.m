//
//  CBDocument.m
//  ComicBook
//
//  Created by cbreak on 2012.12.15.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBDocument.h"

#import "CBFrameFactory.h"

#import "CBComicWindowController.h"

@implementation CBDocument

- (id)init
{
    if (self = [super init])
	{
		// Add your subclass-specific initialization here.
    }
    return self;
}

- (void)makeWindowControllers
{
	CBComicWindowController * cbc = [[CBComicWindowController alloc] init];
	[self addWindowController:cbc];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	[super windowControllerDidLoadNib:aController];
	// Add any code here that needs to be executed once the windowController has
	// loaded the document's window.
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName
			  error:(NSError *__autoreleasing *)outError
{
	frames = [[CBFrameFactory factory] framesFromURL:url error:outError];
	return frames != nil;
}

-(BOOL)isEntireFileLoaded
{
	return NO;
}

@end
