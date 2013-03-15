//
//  CBFrameFactory.m
//  ComicBook
//
//  Created by cbreak on 2012.12.22.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBFrameFactory.h"

#import "CBImageFrame.h"
#import "CBPDFFrame.h"

@implementation CBFrameLoader

+ (CBFrameLoader*)loader
{
	return [[self alloc] init];
}

- (BOOL)canLoadFramesFromURL:(NSURL*)url
{
	return NO;
}

- (NSArray*)loadFramesFromURL:(NSURL*)url error:(NSError **)error
{
	return nil;
}

- (BOOL)canLoadFramesFromDataSource:(id<CBFrameDataSource>)dataSource
{
	return NO;
}

- (NSArray*)loadFramesFromDataSource:(id<CBFrameDataSource>)dataSource error:(NSError **)error
{
	return nil;
}

@end

// URL Loader
@interface CBDirectoryFrameLoader : CBFrameLoader
- (BOOL)canLoadFramesFromURL:(NSURL*)url;
- (NSArray*)loadFramesFromURL:(NSURL*)url error:(NSError **)error;
@end

@implementation CBDirectoryFrameLoader

- (BOOL)canLoadFramesFromURL:(NSURL*)url
{
	NSNumber * isDirectory;
	return [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL] && [isDirectory boolValue];
}

- (NSArray*)loadFramesFromURL:(NSURL*)url error:(NSError **)error
{
	NSFileManager * fm = [NSFileManager defaultManager];
	NSArray * enumProps = [NSArray arrayWithObjects:NSURLTypeIdentifierKey,NSURLIsDirectoryKey,nil];
	NSDirectoryEnumerationOptions enumOptions = NSDirectoryEnumerationSkipsHiddenFiles;
	NSDirectoryEnumerator * dirEnum =
	[fm enumeratorAtURL:url includingPropertiesForKeys:enumProps options:enumOptions
		   errorHandler:^(NSURL *u, NSError *e)
	 {
		 NSLog(@"framesFromDirectoryURL enumerator error: %@ %@", u, e);
		 if (error) *error = e;
		 return YES;
	 }];
	NSMutableArray * frames = [NSMutableArray arrayWithCapacity:1];
	for (NSURL * url in dirEnum)
	{
		NSNumber * isDirectory;
		if ([url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:error] && ![isDirectory boolValue])
		{
			NSArray * subFrames = [[CBFrameFactory factory] framesFromURL:url error:error];
			if (subFrames)
				[frames addObjectsFromArray:subFrames];
		}
	}
	return frames;
}

@end

static CBFrameFactory * CBFrameFactory_staticFactory = nil;

@implementation CBFrameFactory

+ (CBFrameFactory*)factory
{
	return CBFrameFactory_staticFactory;
}

+ (void)initialize
{
	CBFrameFactory_staticFactory = [[CBFrameFactory alloc] init];
}

- (id)init
{
	if (self = [super init])
	{
		frameLoaders = @[
			[CBDirectoryFrameLoader loader],
			[CBPDFFrameLoader loader],
			[CBURLImageFrameLoader loader],
			[CBDataImageFrameLoader loader]
		];
	}
	return self;
}

- (NSArray*)framesFromURL:(NSURL*)url error:(NSError **)error
{
	for (CBFrameLoader * frameLoader in frameLoaders)
	{
		if ([frameLoader canLoadFramesFromURL:url])
		{
			return [frameLoader loadFramesFromURL:url error:error];
		}
	}
	// No valid loader found
	return nil;
}

- (NSArray*)framesFromDataSource:(id<CBFrameDataSource>)dataSource error:(NSError **)error;
{
	for (CBFrameLoader * frameLoader in frameLoaders)
	{
		if ([frameLoader canLoadFramesFromDataSource:dataSource])
		{
			return [frameLoader loadFramesFromDataSource:dataSource error:error];
		}
	}
	// No valid loader found
	return nil;
}

@end
