//
//  CBPage.m
//  ComicBook
//
//  Created by cbreak on 04.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBPage.h"


@implementation CBPage

// To query image

- (NSImage *)image
{
	return nil;
}

- (NSString *)path;
{
	return nil;
}

// To query properties

- (CGFloat)aspect
{
	NSSize s = [self size];
	return s.width/s.height;
}

- (NSSize)size
{
	NSImage * img = [self image];
	if (img)
		return [img size];
	else
		return NSMakeSize(0, -1); // Invalid
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
