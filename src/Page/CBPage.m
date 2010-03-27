//
//  CBPage.m
//  ComicBook
//
//  Created by cbreak on 04.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBPage.h"

#import <ZipKit/ZKDataArchive.h>
#import <ZipKit/ZKCDHeader.h>

#import <XADMaster/XADArchiveParser.h>
#import <XADMaster/CSFileHandle.h>

#import "CBURLPage.h"
#import "CBZipPage.h"
#import "CBXADPage.h"
#import "CBDataPage.h"

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
- (BOOL)isPortrait
{
	return [self aspect] < 1;
}

- (BOOL)isLandscape
{
	return [self aspect] >= 1;
}

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

@synthesize number;

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
	else if ([ZKArchive validArchiveAtPath:[url path]])
	{
		return [CBZipPage pagesFromZipFile:url];
	}
	else if ([XADArchiveParser archiveParserClassForHandle:[CSFileHandle fileHandleForReadingAtPath:[url path]]
													  name:[url path]])
	{
		return [CBXADPage pagesFromArchiveURL:url];
	}
	// Not readable yet, return empty
	return [NSArray array];
}

+ (NSArray*)pagesFromData:(NSData*)data withPath:(NSString*)path
{
	NSArray * imageTypes = [NSImage imageFileTypes];
	NSString * fileExtension = [path pathExtension];
	if ([imageTypes containsObject:fileExtension])
	{
		return [CBDataPage pagesFromImageData:data withPath:path];
	}
	else if ([fileExtension isEqualToString:@"zip"] ||
			 [fileExtension isEqualToString:@"cbz"])
	{
		// Maybe some zip archive data
		NSMutableData * mutableData = [[data mutableCopyWithZone:nil] autorelease];
		return [CBZipPage pagesFromZipData:mutableData withPath:path];
	}
	else if ([fileExtension isEqualToString:@"rar"] ||
			 [fileExtension isEqualToString:@"cbr"])
	{
		// Maybe some rar archive data
		return [CBXADPage pagesFromArchiveData:data withPath:path];
	}
	// Not readable yet, return empty
	return [NSArray array];
}

@end
