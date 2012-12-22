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
			[CBURLImageFrame loader],
			[CBDataImageFrame loader],
			[CBPDFFrame loader]
		];
	}
	return self;
}

- (NSArray*)framesFromURL:(NSURL*)url error:(NSError **)error
{
	NSNumber * isDirectory;
	if ([url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:error])
	{
		if ([isDirectory boolValue])
		{
			return [self framesFromDirectoryURL:url error:error];
		}
		else
		{
			return [self framesFromFileURL:url error:error];
		}
	}
	else
	{
		return nil;
	}
}

- (NSArray*)framesFromDirectoryURL:(NSURL*)url error:(NSError **)error
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
		if ([url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL] && ![isDirectory boolValue])
		{
			NSArray * subFrames = [self framesFromFileURL:url error:error];
			if (subFrames)
				[frames addObjectsFromArray:subFrames];
		}
	}
	return frames;
}

- (NSArray*)framesFromFileURL:(NSURL*)url error:(NSError **)error
{
	for (id<CBFrameLoader> frameLoader in frameLoaders)
	{
		if ([frameLoader canLoadFramesFromURL:url])
		{
			return [frameLoader loadFramesFromURL:url];
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
			return [frameLoader loadFramesFromData:data withPath:path];
		}
	}
	// No valid loader found
	return nil;
}

@end
