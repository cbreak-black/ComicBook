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
	NSArray * frames;
	NSUInteger currentFrame;
}

- (id)initWithURL:(NSURL*)url error:(NSError **)error;

+ (CBComicModel*)comicWithURL:(NSURL*)url error:(NSError **)error;

@property (readonly) NSURL * fileUrl;
@property (atomic,assign) NSUInteger currentFrame;

- (CBFrame*)frameAtIndex:(NSUInteger)idx;

@end
