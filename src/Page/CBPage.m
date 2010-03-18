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
	if (s.width > 0 && s.height > 0)
		return s.width/s.height;
	else
		return 0;
}

- (NSSize)size
{
	NSImageRep * img = [[self image] bestRepresentationForRect:NSMakeRect(0, 0, 0, 0) context:nil hints:nil];
	if (img)
		return NSMakeSize([img pixelsWide], [img pixelsHigh]);
	else
		return NSMakeSize(0, 0); // Invalid
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
