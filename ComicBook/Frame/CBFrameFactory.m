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
#import "CBXADFrame.h"

@implementation CBFrameLoader

+ (CBFrameLoader*)loader
{
	return [[self alloc] init];
}

- (BOOL)canLoadFramesFromURL:(NSURL*)url
{
	return NO;
}

- (BOOL)loadFramesFromURL:(NSURL*)url withBlock:(void (^)(CBFrame*))frameCallback
{
	return NO;
}

- (BOOL)canLoadFramesFromDataSource:(id<CBFrameDataSource>)dataSource
{
	return NO;
}

- (BOOL)loadFramesFromDataSource:(id<CBFrameDataSource>)dataSource withBlock:(void (^)(CBFrame*))frameCallback
{
	return NO;
}

@end

// URL Loader
@interface CBDirectoryFrameLoader : CBFrameLoader
- (BOOL)canLoadFramesFromURL:(NSURL*)url;
- (BOOL)loadFramesFromURL:(NSURL*)url withBlock:(void (^)(CBFrame*))frameCallback;
@end

@implementation CBDirectoryFrameLoader

- (BOOL)canLoadFramesFromURL:(NSURL*)url
{
	NSNumber * isDirectory;
	return [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL] && [isDirectory boolValue];
}

- (BOOL)loadFramesFromURL:(NSURL*)url withBlock:(void (^)(CBFrame*))frameCallback
{
	NSFileManager * fm = [NSFileManager defaultManager];
	NSArray * enumProps = [NSArray arrayWithObjects:NSURLTypeIdentifierKey,NSURLIsDirectoryKey,nil];
	NSDirectoryEnumerationOptions enumOptions = NSDirectoryEnumerationSkipsHiddenFiles;
	NSDirectoryEnumerator * dirEnum =
	[fm enumeratorAtURL:url includingPropertiesForKeys:enumProps options:enumOptions
		   errorHandler:^(NSURL *u, NSError *e)
	 {
		 NSLog(@"framesFromDirectoryURL enumerator error: %@ %@", u, e);
		 return YES;
	 }];
	for (NSURL * url in dirEnum)
	{
		NSNumber * isDirectory;
		if ([url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL] && ![isDirectory boolValue])
		{
			[[CBFrameFactory factory] framesFromURL:url withBlock:frameCallback];
		}
	}
	return YES;
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
			[CBImageFrameLoader loader],
			[CBXADFrameLoader loader]
		];
	}
	return self;
}

- (BOOL)framesFromURL:(NSURL*)url withBlock:(void (^)(CBFrame*))frameCallback;
{
	for (CBFrameLoader * frameLoader in frameLoaders)
	{
		if ([frameLoader canLoadFramesFromURL:url])
		{
			return [frameLoader loadFramesFromURL:url withBlock:frameCallback];
		}
	}
	return NO;
}

- (BOOL)framesFromDataSource:(id<CBFrameDataSource>)dataSource withBlock:(void (^)(CBFrame*))frameCallback;
{
	for (CBFrameLoader * frameLoader in frameLoaders)
	{
		if ([frameLoader canLoadFramesFromDataSource:dataSource])
		{
			return [frameLoader loadFramesFromDataSource:dataSource withBlock:frameCallback];
		}
	}
	return NO;
}

@end
