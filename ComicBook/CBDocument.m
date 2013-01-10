//
//  CBDocument.m
//  ComicBook
//
//  Created by cbreak on 2012.12.15.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBDocument.h"

#import "CBComicWindowController.h"

#import "CBComicModel.h"

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
	comicWindow = [[CBComicWindowController alloc] init];
	comicWindow.model = comic;
	[self addWindowController:comicWindow];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName
			  error:(NSError **)outError
{
	comic = [CBComicModel comicWithURL:url error:outError];
	return comic != nil;
}

-(BOOL)isEntireFileLoaded
{
	return NO;
}

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName
{
	return YES;
}

@end
