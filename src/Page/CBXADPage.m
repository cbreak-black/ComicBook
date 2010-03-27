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
		NSArray * imageTypes = [NSImage imageFileTypes];
		NSString * fileExtension = [[[dict objectForKey:XADFileNameKey] string] pathExtension];
		if ([imageTypes containsObject:fileExtension])
		{
			// Seems to be an image file
			archive = [parser retain];
			header = [dict retain];
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
	[archive release];
	[header release];
	[img release];
	[super dealloc];
}

// Loads the Image lazily (internal)
- (BOOL)loadImage
{
	if (!img)
	{
		NSData * imgData;
		@synchronized (archive)
		{
			// Seems XADArchiveParsers aren't thread safe
			imgData = [[archive handleForEntryWithDictionary:header wantChecksum:NO] remainingFileContents];
		}
		img = [[NSImage alloc] initWithData:imgData];
		if (!img || ![img isValid])
		{
			// TODO: Set img to error image
			NSLog(@"Error loading image from archive, file %@", [self path]);
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
	return [[archive filename] stringByAppendingPathComponent:[[header objectForKey:XADFileNameKey] string]];
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
