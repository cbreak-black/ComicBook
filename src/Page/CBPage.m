//
//  CBPage.m
//  ComicBook
//
//  Created by cbreak on 04.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBPage.h"


@implementation CBPage

- (NSImage *)image
{
	return nil;
}

- (NSString *)path;
{
	return nil;
}


// NSDiscardableContent
- (BOOL)beginContentAccess
{
	return NO;
}

- (void)endContentAccess
{
}

- (void)discardContentIfPossible
{
}

- (BOOL)isContentDiscarded
{
	return YES;
}

@end
