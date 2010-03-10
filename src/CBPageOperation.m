//
//  CBPageOperation.m
//  ComicBook
//
//  Created by cbreak on 10.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBPageOperation.h"

#import "CBPage.h"

@implementation CBPageOperation

- (void)dealloc
{
	[page release];
	[super dealloc];
}

@synthesize page;

@end


@implementation CBPreloadOperation

- (void)main
{
	[self.page beginContentAccess];
}

@end


@implementation CBUnloadOperation

- (void)main
{
	[self.page endContentAccess];
	[self.page discardContentIfPossible];
}

@end
