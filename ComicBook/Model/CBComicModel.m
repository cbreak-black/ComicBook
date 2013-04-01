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
		NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
		comicURL = [url fileReferenceURL];
		currentFrameIdx = 0;
		layoutMode = (CBComicLayoutMode)[defaults integerForKey:@"defaultLayoutMode"];
		direction = (CBComicDirection)[defaults integerForKey:@"defaultDirection"];
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
			dispatch_async(dispatch_get_main_queue(), ^(){
				[self sortFrames];
			});
		});
	}
	return self;
}

+ (void)initialize
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:@{
		@"defaultLayoutMode": [NSNumber numberWithInteger:kCBComicLayoutDouble],
		@"defaultDirection": [NSNumber numberWithInteger:kCBDirectionRightToLeft]
	 }];
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

@synthesize frames;

- (void)setCurrentFrameIdx:(NSUInteger)newFrameIdx
{
	[self willChangeValueForKey:@"currentFrameSet"];
	if (newFrameIdx >= [frames count])
		newFrameIdx = [frames count]-1;
	currentFrameIdx = newFrameIdx;
	[self didChangeValueForKey:@"currentFrameSet"];
}

@synthesize currentFrameIdx;

- (NSIndexSet*)currentFrameSet
{
	return [NSIndexSet indexSetWithIndex:currentFrameIdx];
}

- (void)setCurrentFrameSet:(NSIndexSet *)currentFrameSet
{
	if ([currentFrameSet count] > 0)
		[self setCurrentFrameIdx:[currentFrameSet firstIndex]];
}

@synthesize layoutMode;
@synthesize direction;

- (void)shiftCurrentFrameIdx:(NSInteger)offset
{
	NSInteger newFrameIdx = currentFrameIdx + offset;
	if (newFrameIdx < 0)
		newFrameIdx = 0;
	if (newFrameIdx >= [frames count])
		newFrameIdx = [frames count]-1;
	if (currentFrameIdx != newFrameIdx)
	{
		[self willChangeValueForKey:@"currentFrameSet"];
		[self willChangeValueForKey:@"currentFrameIdx"];
		currentFrameIdx = newFrameIdx;
		[self didChangeValueForKey:@"currentFrameIdx"];
		[self didChangeValueForKey:@"currentFrameSet"];
	}
}

- (void)addFrame:(CBFrame*)frame
{
	[frame filterPathWithRoot:[self comicPath]];
	NSIndexSet * indexes = [NSIndexSet indexSetWithIndex:[frames count]];
	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"frames"];
	[self willChangeValueForKey:@"frameCount"];
	[frames addObject:frame];
	[self didChangeValueForKey:@"frameCount"];
	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"frames"];
}

- (void)addFrames:(NSArray*)frames_
{
	NSString * path = [self comicPath];
	for (CBFrame * frame in frames_)
		[frame filterPathWithRoot:path];
	NSIndexSet * indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([frames count], [frames_ count])];
	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"frames"];
	[self willChangeValueForKey:@"frameCount"];
	[frames addObjectsFromArray:frames_];
	[self didChangeValueForKey:@"frameCount"];
	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"frames"];
}

- (CBFrame*)frameAtIndex:(NSUInteger)idx
{
	if (idx < [frames count])
		return [frames objectAtIndex:idx];
	return nil;
}

- (void)sortFrames
{
	NSIndexSet * indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [frames count])];
	[self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"frames"];
	[frames sortUsingComparator:^(CBFrame * a, CBFrame * b)
	 { return [a.filteredPath compare:b.filteredPath options:NSNumericSearch|NSCaseInsensitiveSearch]; }];
	[self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"frames"];
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
		NSNumber * d = [dict objectForKey:@"direction"];
		if (d) direction = (CBComicDirection)[d unsignedIntegerValue];
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
		@"direction": [NSNumber numberWithUnsignedInteger:direction],
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
