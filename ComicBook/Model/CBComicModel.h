//
//  CBComicModel.h
//  ComicBook
//
//  Created by cbreak on 2012.12.29.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CBConstants.h"

@class CBFrame;

@interface CBComicModel : NSObject
{
	NSURL * comicURL;
	NSMutableArray * frames;
	NSUInteger currentFrameIdx;
	CBComicLayoutMode layoutMode;
	CBComicDirection direction;
}

- (id)initWithURL:(NSURL*)url error:(NSError **)error;

+ (CBComicModel*)comicWithURL:(NSURL*)url error:(NSError **)error;

@property (nonatomic,readonly) NSURL * comicURL;
@property (nonatomic,readonly) NSString * comicPath;
@property (nonatomic,readonly) NSUInteger frameCount;
@property (nonatomic,readonly) NSArray * frames;
@property (nonatomic,assign) NSUInteger currentFrameIdx;
@property (nonatomic,retain) NSIndexSet * currentFrameSet;
@property (nonatomic,assign) CBComicLayoutMode layoutMode;
@property (nonatomic,assign) CBComicDirection direction;

- (void)shiftCurrentFrameIdx:(NSInteger)offset;

- (void)addFrame:(CBFrame*)frame;
- (void)addFrames:(NSArray*)frames;
- (CBFrame*)frameAtIndex:(NSUInteger)idx;

- (void)sortFrames;

- (void)loadPersistentData;
- (void)storePersistentData;

+ (NSDictionary*)persistentDictionaryForURL:(NSURL*)url;
+ (void)storePersistentDictionary:(NSDictionary*)dict forURL:(NSURL*)url;

@end
