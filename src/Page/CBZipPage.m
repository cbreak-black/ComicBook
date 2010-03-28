//
//  CBZipPage.m
//  ComicBook
//
//  Created by cbreak on 19.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBZipPage.h"

#import <ZipKit/ZKDataArchive.h>
#import <ZipKit/ZKCDHeader.h>

@implementation CBZipPage

- (id)initWithArchive:(ZKDataArchive *)fileArchive header:(ZKCDHeader*)fileHeader
{
	self = [super init];
	if (self)
	{
		NSArray * imageTypes = [NSImage imageFileTypes];
		NSString * fileExtension = [fileHeader.filename pathExtension];
		if (![fileHeader isDirectory] &&
			![fileHeader isSymLink] &&
			![fileHeader isResourceFork] &&
			[imageTypes containsObject:fileExtension])
		{
			// Seems to be an image file
			archive = [fileArchive retain];
			header = [fileHeader retain];
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
	[archive release];
	[header release];
	[super dealloc];
}

// Loads the Image lazily (internal)
- (BOOL)loadImage
{
	NSImage * img = self.image;
	if (!img)
	{
		NSDictionary * fileAttributes;
		NSData * imgData = [archive inflateFile:header attributes:&fileAttributes];
		img = [[NSImage alloc] initWithData:imgData];
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
			NSLog(@"Error loading image from zip archive, file %@", [self path]);
		}
	}
	return img != nil;
}

- (NSString *)path;
{
	return [[archive archivePath] stringByAppendingPathComponent:[header filename]];
}

// Creation

+ (NSArray*)pagesFromZipFile:(NSURL*)zipPath
{
	NSMutableData * zipData = [[NSMutableData alloc] initWithContentsOfURL:zipPath options:NSDataReadingMapped error:NULL];
	return [self pagesFromZipData:[zipData autorelease] withPath:[zipPath path]];
}

+ (NSArray*)pagesFromZipData:(NSMutableData*)zipData withPath:(NSString*)zipPath
{
	ZKDataArchive * zipArchive = [ZKDataArchive archiveWithArchiveData:zipData];
	if (zipArchive)
	{
		zipArchive.archivePath = zipPath;
		NSMutableArray * pages = [NSMutableArray arrayWithCapacity:1];
		for (ZKCDHeader * header in zipArchive.centralDirectory)
		{
			CBZipPage * page = [[CBZipPage alloc] initWithArchive:zipArchive header:header];
			if (page)
			{
				[pages addObject:page];
				[page release];
			}
			else if (header.uncompressedSize > 0)
			{
				// Try to use data
				NSDictionary * fileAttributes;
				NSString * path = [[zipArchive archivePath] stringByAppendingPathComponent:[header filename]];
				NSData * data = [zipArchive inflateFile:header attributes:&fileAttributes];
				[pages addObjectsFromArray:[CBPage pagesFromData:data withPath:path]];
			}
		}
		return pages;
	}
	else
	{
		return [NSArray array];
	}
}

@end
