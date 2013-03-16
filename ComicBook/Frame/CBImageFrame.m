//
//  CBImageFrame.m
//  ComicBook
//
//  Created by cbreak on 2012.12.22.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBImageFrame.h"

static BOOL canLoadFrameFromFormat(NSString * extension)
{
	// imageFileTypes contains extensions
	return [[NSImage imageFileTypes] containsObject:extension];
}

static BOOL canLoadFramesFromURL(NSURL * url)
{
	NSString * urlType;
	BOOL success = [url getResourceValue:&urlType forKey:NSURLTypeIdentifierKey error:NULL];
	if (success && urlType)
	{
		// imageTypes contains UTIs
		return [[NSImage imageTypes] containsObject:urlType];
	}
	return NO;
}

// URL Loader

@implementation CBURLImageFrameLoader

- (BOOL)canLoadFramesFromURL:(NSURL*)url
{
	return canLoadFramesFromURL(url);
}

- (NSArray*)loadFramesFromURL:(NSURL*)url error:(NSError **)error
{
	CBURLImageFrame * urlFrames = [[CBURLImageFrame alloc] initWithURL:url];
	if (urlFrames)
		return @[urlFrames];
	return nil;
}

@end

// Data Loader

@implementation CBDataImageFrameLoader

- (BOOL)canLoadFramesFromDataSource:(id<CBFrameDataSource>)dataSource;
{
	NSString * fileExtension = [[dataSource framePath] pathExtension];
	return canLoadFrameFromFormat(fileExtension);
}

- (NSArray*)loadFramesFromDataSource:(id<CBFrameDataSource>)dataSource error:(NSError **)error;
{
	CBDataImageFrame * dataFrame = [[CBDataImageFrame alloc] initWithDataSource:dataSource];
	if (dataFrame)
		return @[dataFrame];
	return nil;
}

@end

// URL Frame
@implementation CBURLImageFrame

- (id)initWithURL:(NSURL *)frameURL
{
	if (self = [super init])
	{
		if (canLoadFramesFromURL(frameURL))
		{
			url = frameURL;
		}
		else
		{
			self = nil;
		}
	}
	return self;
}

- (NSImage*)image
{
	NSImage * image = [[NSImage alloc] initWithContentsOfURL:url];
	if (image && [image isValid])
	{
		return image;
	}
	NSLog(@"Error loading image from url %@", [self path]);
	return [super image];
}

- (NSString *)path;
{
	return [url path];
}

@end

// Data Frame
@implementation CBDataImageFrame

- (id)initWithDataSource:(id<CBFrameDataSource>)dataSource_
{
	if (self = [super init])
	{
		NSString * fileExtension = [[dataSource_ framePath] pathExtension];
		if (canLoadFrameFromFormat(fileExtension))
		{
			dataSource = dataSource_;
		}
		else
		{
			self = nil;
		}
	}
	return self;
}

- (NSImage*)image
{
	NSImage * image = [[NSImage alloc] initWithData:[dataSource frameData]];
	if (image && [image isValid])
	{
		return image;
	}
	NSLog(@"Error loading image from data with path %@", [self path]);
	return [super image];
}

- (NSString*)path
{
	return [dataSource framePath];
}

@end
