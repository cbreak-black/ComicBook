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

@implementation CBImageFrameLoader

- (BOOL)canLoadFramesFromURL:(NSURL*)url
{
	return canLoadFramesFromURL(url);
}

- (BOOL)loadFramesFromURL:(NSURL*)url withBlock:(void (^)(CBFrame*))frameCallback
{
	CBURLImageFrame * imageFrame = [[CBURLImageFrame alloc] initWithURL:url];
	if (imageFrame)
	{
		frameCallback(imageFrame);
		return YES;
	}
	return NO;
}

- (BOOL)canLoadFramesFromDataSource:(id<CBFrameDataSource>)dataSource;
{
	NSString * fileExtension = [[dataSource framePath] pathExtension];
	return canLoadFrameFromFormat(fileExtension);
}

- (BOOL)loadFramesFromDataSource:(id<CBFrameDataSource>)dataSource withBlock:(void (^)(CBFrame*))frameCallback
{
	CBDataImageFrame * imageFrame = [[CBDataImageFrame alloc] initWithDataSource:dataSource];
	if (imageFrame)
	{
		frameCallback(imageFrame);
		return YES;
	}
	return NO;
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
