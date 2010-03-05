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
		NSArray * imageTypes = [NSImage imageTypes];
		NSString * urlType;
		[imgURL getResourceValue:&urlType forKey:NSURLTypeIdentifierKey error:NULL];
		if (urlType && [imageTypes containsObject:urlType])
		{
			// Known type
			url = imgURL;
			img = [[NSImage alloc] initByReferencingURL:url];
			if (!img)
			{
				// Could not allocate image
				[self release];
				return nil;
			}
		}
		else
		{
			// Could not read type
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
