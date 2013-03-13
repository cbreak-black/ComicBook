//
//  CBComicModel.m
//  ComicBook
//
//  Created by cbreak on 2012.12.29.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBComicModel.h"

#import "CBFrameFactory.h"

#import <Foundation/NSUserDefaults.h>

@implementation CBComicModel

- (id)initWithURL:(NSURL*)url error:(NSError **)error
{
	if (self = [super init])
	{
		fileUrl = [url fileReferenceURL];
		currentFrame = 0;
		frames = [[CBFrameFactory factory] framesFromURL:url error:error];
		if (!frames)
			self = nil;
		[self loadPersistentData];
	}
	return self;
}

+ (CBComicModel*)comicWithURL:(NSURL*)url error:(NSError **)error
{
	return [[self alloc] initWithURL:url error:error];
}

@synthesize fileUrl;

- (NSUInteger)frameCount
{
	return [frames count];
}

@synthesize currentFrame;

- (CBFrame*)frameAtIndex:(NSUInteger)idx
{
	if (idx < [frames count])
		return [frames objectAtIndex:idx];
	return nil;
}

- (void)loadPersistentData
{
	NSDictionary * dict = [CBComicModel persistentDictionaryForURL:fileUrl];
	if (dict)
	{
		NSNumber * n = [dict objectForKey:@"currentFrame"];
		if (n)
			currentFrame = [n unsignedIntegerValue];
	}
}

- (void)storePersistentData
{
	NSData * bookmark = [fileUrl bookmarkDataWithOptions:NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess
						  includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
	NSDictionary * dict = @{
		@"name": [fileUrl lastPathComponent],
		@"currentFrame": [NSNumber numberWithUnsignedInteger:currentFrame],
		@"bookmark": bookmark
	};
	[CBComicModel storePersistentDictionary:dict forURL:fileUrl];
}

+ (NSDictionary*)persistentDictionaryForURL:(NSURL*)url;
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary * comics = [defaults dictionaryForKey:@"comics"];
	if (comics)
		return [comics objectForKey:[url absoluteString]];
	return nil;
}

+ (void)storePersistentDictionary:(NSDictionary*)dict forURL:(NSURL*)url
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary * originalComics = [defaults dictionaryForKey:@"comics"];
	NSMutableDictionary * comics;
	if (originalComics)
		comics = [originalComics mutableCopy];
	else
		comics = [NSMutableDictionary dictionary];
	[comics setObject:dict forKey:[url absoluteString]];
	[defaults setObject:comics forKey:@"comics"];
	[defaults synchronize];
}

@end
