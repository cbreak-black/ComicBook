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

- (BOOL)loadFramesFromURL:(NSURL*)url withBlock:(void (^)(CBFrame*))frameCallback
{
	return [CBXADProxy loadArchiveAtURL:url withBlock:^(CBXADArchiveFileProxy * file)
	{
		[self framesFromArchiveFile:file withBlock:frameCallback];
	}];
}

- (BOOL)canLoadFramesFromDataSource:(id<CBFrameDataSource>)dataSource
{
	return NO;
}

- (BOOL)loadFramesFromDataSource:(id<CBFrameDataSource>)dataSource withBlock:(void (^)(CBFrame*))frameCallback
{
	// This would require a lot of RAM, so only implement if really needed...
	return NO;
}

- (BOOL)framesFromArchiveFile:(CBXADArchiveFileProxy*)archiveFile withBlock:(void (^)(CBFrame*))frameCallback
{
	CBXADFrameDataSource * source = [[CBXADFrameDataSource alloc] initWithXADArchive:archiveFile];
	// Maybe one of the generic handler can handle the file
	if ([[CBFrameFactory factory] framesFromDataSource:source withBlock:frameCallback])
		return YES;
	// Otherwise it may be an archive, recurse into it
	if ([CBXADProxy loadArchiveFromArchiveFile:archiveFile withBlock:^(CBXADArchiveFileProxy * file)
		 { [self framesFromArchiveFile:file withBlock:frameCallback]; }])
	{
		return YES;
	}
	return NO;
}

@end
