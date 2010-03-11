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
			img = nil;
			accessCounter = 0; // Should be 1, but this class lazily loads the Data
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
	[img release];
	[super dealloc];
}

// Loads the Image lazily (internal)
- (BOOL)loadImage
{
	if (!img)
	{
		img = [[NSImage alloc] initWithContentsOfURL:url];
		if (!img || ![img isValid])
		{
			// TODO: Set img to error image
			NSLog(@"Error loading image from URL %@", [url description]);
			return NO;
		}
		else
		{
			return YES;
		}
	}
	return img != nil && [img isValid];
}

- (NSImage *)image
{
	NSImage * rImg;
	@synchronized (self)
	{
		[self loadImage];
		rImg = [img retain];
	}
	return [rImg autorelease];
}

- (NSString *)path;
{
	return [url path];
}

// NSDiscardableContent
- (BOOL)beginContentAccess
{
	BOOL r = NO;
	@synchronized (self)
	{
		if ([self loadImage])
		{
			accessCounter++;
			r = YES;
		}
		else
		{
			r = NO;
		}
	}
	return r;
}

- (void)endContentAccess
{
	@synchronized (self)
	{
		accessCounter--;
	}
}

- (void)discardContentIfPossible
{
	@synchronized (self)
	{
		if (accessCounter <= 0)
		{
			[img release];
			img = nil;
		}
	}
}

- (BOOL)isContentDiscarded
{
	return img == nil;
}

@end
