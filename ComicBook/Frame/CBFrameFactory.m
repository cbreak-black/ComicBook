//
//  CBFrameFactory.m
//  ComicBook
//
//  Created by cbreak on 2012.12.22.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBFrameFactory.h"

#include "CBImageFrame.h"
#include "CBPDFFrame.h"

// URL Loader
@interface CBDirectoryFrameLoader : NSObject<CBFrameLoader>
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

- (BOOL)canLoadFramesFromData:(NSData*)data withPath:(NSString*)path
{
	return NO;
}

- (NSArray*)loadFramesFromData:(NSData*)data withPath:(NSString*)path error:(NSError **)error
{
	return nil;
}

@end

static CBFrameFactory * CBFrameFactory_staticFactory = nil;

@implementation CBFrameFactory

+ (CBFrameFactory*)factory
{
	if (!CBFrameFactory_staticFactory)
		CBFrameFactory_staticFactory = [[CBFrameFactory alloc] init];
	return CBFrameFactory_staticFactory;
}

- (id)init
{
	if (self = [super init])
	{
		frameLoaders = @[
			[[CBDirectoryFrameLoader alloc] init],
			[CBURLImageFrame loader],
			[CBDataImageFrame loader],
			[CBPDFFrame loader]
		];
	}
	return self;
}

- (NSArray*)framesFromURL:(NSURL*)url error:(NSError **)error
{
	for (id<CBFrameLoader> frameLoader in frameLoaders)
	{
		if ([frameLoader canLoadFramesFromURL:url])
		{
			return [frameLoader loadFramesFromURL:url error:error];
		}
	}
	// No valid loader found
	return nil;
}

- (NSArray*)framesFromData:(NSData*)data withPath:(NSString*)path error:(NSError **)error
{
	for (id<CBFrameLoader> frameLoader in frameLoaders)
	{
		if ([frameLoader canLoadFramesFromData:data withPath:path])
		{
			return [frameLoader loadFramesFromData:data withPath:path error:error];
		}
	}
	// No valid loader found
	return nil;
}

@end
