//
//  CBComicModel.m
//  ComicBook
//
//  Created by cbreak on 2012.12.29.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBComicModel.h"

#import "CBFrameFactory.h"
#import "CBFrame.h"

#import <Foundation/NSUserDefaults.h>

#import <dispatch/dispatch.h>

@implementation CBComicModel

- (id)initWithURL:(NSURL*)url error:(NSError **)error
{
	if (self = [super init])
	{
		comicURL = [url fileReferenceURL];
		currentFrameIdx = 0;
		frames = [NSMutableArray arrayWithCapacity:40];
		[self loadPersistentData];
		// Asyncronously load frames
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^()
		{
			[[CBFrameFactory factory] framesFromURL:url withBlock:^(CBFrame * frame){
				dispatch_async(dispatch_get_main_queue(), ^(){
					[self addFrame:frame];
				});
			}];
		});
	}
	return self;
}

+ (CBComicModel*)comicWithURL:(NSURL*)url error:(NSError **)error
{
	return [[self alloc] initWithURL:url error:error];
}

@synthesize comicURL;

- (NSString*)comicPath
{
	return [[[comicURL filePathURL] path] stringByAppendingString:@"/"];
}

- (NSUInteger)frameCount
{
	return [frames count];
}

- (void)setCurrentFrameIdx:(NSUInteger)newFrameIdx
{
	if (newFrameIdx >= [frames count])
		newFrameIdx = [frames count]-1;
	currentFrameIdx = newFrameIdx;
}

@synthesize currentFrameIdx;

@synthesize layoutMode;

- (void)shiftCurrentFrameIdx:(NSInteger)offset
{
	NSInteger newFrameIdx = currentFrameIdx + offset;
	if (newFrameIdx < 0)
		newFrameIdx = 0;
	if (newFrameIdx >= [frames count])
		newFrameIdx = [frames count]-1;
	if (currentFrameIdx != newFrameIdx)
	{
		[self willChangeValueForKey:@"currentFrameIdx"];
		currentFrameIdx = newFrameIdx;
		[self didChangeValueForKey:@"currentFrameIdx"];
	}
}

- (void)addFrame:(CBFrame*)frame
{
	[frame filterPathWithRoot:[self comicPath]];
	[self willChangeValueForKey:@"frameCount"];
	[frames addObject:frame];
	[self didChangeValueForKey:@"frameCount"];
}

- (void)addFrames:(NSArray*)frames_
{
	NSString * path = [self comicPath];
	for (CBFrame * frame in frames_)
		[frame filterPathWithRoot:path];
	[frames addObjectsFromArray:frames_];
}

- (CBFrame*)frameAtIndex:(NSUInteger)idx
{
	if (idx < [frames count])
		return [frames objectAtIndex:idx];
	return nil;
}

- (void)loadPersistentData
{
	NSDictionary * dict = [CBComicModel persistentDictionaryForURL:comicURL];
	if (dict)
	{
		NSNumber * n = [dict objectForKey:@"currentFrameIdx"];
		if (n) currentFrameIdx = [n unsignedIntegerValue];
		NSNumber * l = [dict objectForKey:@"layoutMode"];
		if (l) layoutMode = (CBComicLayoutMode)[l unsignedIntegerValue];
	}
}

- (void)storePersistentData
{
	NSData * bookmark = [comicURL bookmarkDataWithOptions:NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess
						  includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
	NSDictionary * dict = @{
		@"name": [comicURL lastPathComponent],
		@"currentFrameIdx": [NSNumber numberWithUnsignedInteger:currentFrameIdx],
		@"layoutMode": [NSNumber numberWithUnsignedInteger:layoutMode],
		@"bookmark": bookmark
	};
	[CBComicModel storePersistentDictionary:dict forURL:comicURL];
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
