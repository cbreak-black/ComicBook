//
//  CBXADPage.m
//  ComicBook
//
//  Created by cbreak on 27.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBXADPage.h"

#import <XADMaster/XADArchiveParser.h>
#import <XADMaster/XADPath.h>
#import <XADMaster/CSMemoryHandle.h>

@implementation CBXADPage

- (id)initWithArchiveParser:(XADArchiveParser *)parser dictionary:(NSDictionary *)dict
{
	self = [super init];
	if (self)
	{
		NSMutableArray * imageTypes = [[NSImage imageFileTypes] mutableCopy];
		[imageTypes removeObject:@"pdf"];
		NSString * fileExtension = [[[dict objectForKey:XADFileNameKey] string] pathExtension];
		if ([imageTypes containsObject:fileExtension])
		{
			// Seems to be an image file
			archive = [parser retain];
			header = [dict retain];
		}
		else
		{
			// Could not read type
			[self release];
			self = nil;
		}
		[imageTypes release];
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
		NSData * imgData;
		@synchronized (archive)
		{
			// Seems XADArchiveParsers aren't thread safe
			imgData = [[archive handleForEntryWithDictionary:header wantChecksum:NO] remainingFileContents];
		}
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
			NSLog(@"Error loading image from archive, file %@", [self path]);
		}
	}
	return img != nil;
}

- (NSString *)path;
{
	return [[archive filename] stringByAppendingPathComponent:[[header objectForKey:XADFileNameKey] string]];
}

// Creation

+ (NSArray*)pagesFromArchiveURL:(NSURL*)archivePath
{
	return [self pagesFromArchiveParser:[XADArchiveParser archiveParserForPath:[archivePath path]]];
}

+ (NSArray*)pagesFromArchiveData:(NSData*)archiveData withPath:(NSString*)archivePath
{
	CSHandle * handle = [CSMemoryHandle memoryHandleForReadingData:archiveData];
	return [self pagesFromArchiveParser:[XADArchiveParser archiveParserForHandle:handle name:archivePath]];
}

+ (NSArray*)pagesFromArchiveParser:(XADArchiveParser*)archiveParser
{
	if (archiveParser)
	{
		CBXADPageCreator * pageCreator = [[[CBXADPageCreator alloc] init] autorelease];
		[archiveParser setDelegate:pageCreator];
		[archiveParser parse];
		return pageCreator.pages;
	}
	else
	{
		return [NSArray array];
	}
}

@end

@implementation CBXADPageCreator

- (id)init
{
	self = [super init];
	if (self)
	{
		pages = [[NSMutableArray alloc] initWithCapacity:1];
	}
	return self;
}

- (void)dealloc
{
	[pages release];
	[super dealloc];
}

- (void)archiveParser:(XADArchiveParser *)parser foundEntryWithDictionary:(NSDictionary *)dict
{
	CBXADPage * page = [[CBXADPage alloc] initWithArchiveParser:parser dictionary:dict];
	if (page)
	{
		[pages addObject:page];
		[page release];
	}
	else
	{
		NSString * path = [[parser filename] stringByAppendingPathComponent:[[dict objectForKey:XADFileNameKey] string]];
		NSData * data = [[parser handleForEntryWithDictionary:dict wantChecksum:NO] remainingFileContents];;
		[pages addObjectsFromArray:[CBPage pagesFromData:data withPath:path]];
	}
}

- (BOOL)archiveParsingShouldStop:(XADArchiveParser *)parser
{
	return NO;
}

- (void)archiveParserNeedsPassword:(XADArchiveParser *)parser
{
}

@synthesize pages;

@end
