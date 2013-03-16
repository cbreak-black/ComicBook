//
//  CBXADFrame.m
//  ComicBook
//
//  Created by cbreak on 2013.03.15.
//  Copyright (c) 2013 the-color-black.net. All rights reserved.
//

#import "CBXADFrame.h"

#import "CBXADProxy.h"

@implementation CBXADFrameDataSource

- (id)initWithXADArchive:(CBXADArchiveFileProxy*)archive_
{
	if (self = [super init])
	{
		archive = archive_;
	}
	return self;
}

- (NSData*)frameData
{
	return [archive data];
}

- (NSString*)framePath
{
	return [archive path];
}

@end


@implementation CBXADFrameLoader

- (BOOL)canLoadFramesFromURL:(NSURL*)url
{
	return [CBXADProxy canLoadArchiveAtURL:url];
}

- (NSArray*)loadFramesFromURL:(NSURL*)url error:(NSError **)error
{
	NSArray * files = [CBXADProxy loadArchiveAtURL:url error:error];
	if (files)
	{
		return [self framesFromArchiveFiles:files];
	}
	return nil;
}

- (BOOL)canLoadFramesFromData:(NSData*)data withPath:(NSString*)path
{
	return NO;
}

- (NSArray*)loadFramesFromData:(NSData*)data withPath:(NSString*)path error:(NSError **)error
{
	// This would require a lot of RAM, so only implement if really needed...
	return nil;
}

- (NSArray*)framesFromArchiveFile:(CBXADArchiveFileProxy*)archiveFile
{
	CBXADFrameDataSource * source = [[CBXADFrameDataSource alloc] initWithXADArchive:archiveFile];
	// One of the generic handler can handle the file
	NSArray * frames = [[CBFrameFactory factory] framesFromDataSource:source error:nil];
	if (frames)
		return frames;
	// It is an archive, recurse into it
	NSArray * archiveFiles = [CBXADProxy loadArchiveFromArchiveFile:archiveFile error:nil];
	if (archiveFiles)
		return [self framesFromArchiveFiles:archiveFiles];
	// Couldn't be handled
	return nil;
}

- (NSArray*)framesFromArchiveFiles:(NSArray*)archiveFiles
{
	NSMutableArray * allFrames = [NSMutableArray arrayWithCapacity:[archiveFiles count]];
	for (CBXADArchiveFileProxy * file in archiveFiles)
	{
		NSArray * frames = [self framesFromArchiveFile:file];
		if (frames)
		{
			[allFrames addObjectsFromArray:frames];
		}
	}
	return allFrames;
}

@end
