//
//  CBPage.m
//  ComicBook
//
//  Created by cbreak on 04.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBPage.h"

#import "CBURLPage.h"

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

// Factories
+ (NSArray*)pagesFromURL:(NSURL*)url
{
	NSNumber * isDirectory;
	[url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
	if ([isDirectory boolValue])
	{
		return [self pagesFromDirectoryURL:url];
	}
	else
	{
		return [self pagesFromFileURL:url];
	}
}

+ (NSArray*)pagesFromDirectoryURL:(NSURL*)url
{
	NSFileManager * fm = [[NSFileManager alloc] init];
	NSDirectoryEnumerator * de =
	[fm enumeratorAtURL:url includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLTypeIdentifierKey,NSURLIsDirectoryKey,nil]
				options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:^(NSURL *url, NSError *error)
	 {
		 NSLog(@"pagesFromDirectoryURL enumerator error: %@", error);
		 return YES;
	 }];
	NSMutableArray * pages = [NSMutableArray arrayWithCapacity:1];
	for (NSURL * url in de)
	{
		NSNumber * isDirectory;
		if ([url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL])
		{
			if (![isDirectory boolValue]) // Some kind of file
			{
				[pages addObjectsFromArray:[self pagesFromFileURL:url]];
			};
		};
	};
	[fm release];
	return pages;
}

+ (NSArray*)pagesFromFileURL:(NSURL*)url
{
	CBPage * page = [[CBURLPage alloc] initWithURL:url];
	if (page)
	{
		[page autorelease];
		return [NSArray arrayWithObject:page];
	}
	else
	{
		// Not an image file, check archive file
	}
	return [NSArray array];
}

@end
