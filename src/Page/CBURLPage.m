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
			url = [imgURL retain];
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
	[url release];
	[super dealloc];
}

// Loads the Image lazily (internal)
- (BOOL)loadImage
{
	NSImage * img = self.image;
	if (!img)
	{
		img = [[NSImage alloc] initWithContentsOfURL:url];
		if (img && [img isValid])
		{
			self.image = img;
			[img release];
		}
		else
		{
			// TODO: Set img to error image
			[img release];
			img = nil;
			NSLog(@"Error loading image from url %@", [self path]);
		}
	}
	return img != nil;
}

- (NSString *)path;
{
	return [url path];
}

@end
