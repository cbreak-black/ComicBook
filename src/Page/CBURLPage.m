//
//  CBURLPage.m
//  ComicBook
//
//  Created by cbreak on 04.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBURLPage.h"


@implementation CBURLPage

- (id)initWithURL:(NSURL *)imgURL
{
	self = [super init];
	if (self)
	{
		url = imgURL;
		img = [[NSImage alloc] initByReferencingURL:url];
		if (!img)
		{
			[self release];
			return nil;
		}
	}
	return self;
}

- (NSImage *)image
{
	return img;
}

- (NSString *)path;
{
	return [url path];
}

@end
