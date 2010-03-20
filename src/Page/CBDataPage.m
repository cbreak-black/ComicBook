//
//  CBDataPage.m
//  ComicBook
//
//  Created by cbreak on 20.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBDataPage.h"


@implementation CBDataPage

- (id)initWithImageData:(NSData*)imgData withPath:(NSString*)imgPath
{
	self = [super init];
	if (self)
	{
		img = [[NSImage alloc] initWithData:imgData];
		if (img && [img isValid])
		{
			// Seems to be an image file
			path = [imgPath retain];
		}
		else
		{
			// Could not read type
			[self release];
			self = nil;
		}
	}
	return self;
}

- (void)dealloc
{
	[path release];
	[img release];
	[super dealloc];
}

@synthesize image = img;
@synthesize path;

// NSDiscardableContent
- (BOOL)beginContentAccess
{
	return img != nil;
}

- (BOOL)isContentDiscarded
{
	return img == nil;
}

// Factories
+ (NSArray*)pagesFromImageData:(NSData*)imgData withPath:(NSString*)imgPath
{
	// Single image data
	CBPage * page = [[CBDataPage alloc] initWithImageData:imgData withPath:imgPath];
	if (page)
	{
		NSArray * pages = [NSArray arrayWithObject:page];
		[page release];
		return pages;
	}
	else
	{
		return [NSArray array];
	}
}

@end
