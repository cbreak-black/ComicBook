//
//  CBComicModel.h
//  ComicBook
//
//  Created by cbreak on 2012.12.29.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CBFrame;

@interface CBComicModel : NSObject
{
	NSURL * fileUrl;
	NSUInteger currentFrameIdx;
	NSArray * frames;
}

- (id)initWithURL:(NSURL*)url error:(NSError **)error;

+ (CBComicModel*)comicWithURL:(NSURL*)url error:(NSError **)error;

@property (nonatomic,readonly) NSURL * fileUrl;
@property (nonatomic,readonly) NSUInteger frameCount;
@property (atomic,assign) NSUInteger currentFrameIdx;

- (CBFrame*)frameAtIndex:(NSUInteger)idx;

- (void)loadPersistentData;
- (void)storePersistentData;

+ (NSDictionary*)persistentDictionaryForURL:(NSURL*)url;
+ (void)storePersistentDictionary:(NSDictionary*)dict forURL:(NSURL*)url;

@end
