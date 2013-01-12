//
//  CBFrameFactory.h
//  ComicBook
//
//  Created by cbreak on 2012.12.22.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CBFrameLoader : NSObject
+ (CBFrameLoader*)loader;
- (BOOL)canLoadFramesFromURL:(NSURL*)url;
- (NSArray*)loadFramesFromURL:(NSURL*)url error:(NSError **)error;
- (BOOL)canLoadFramesFromData:(NSData*)data withPath:(NSString*)path;
- (NSArray*)loadFramesFromData:(NSData*)data withPath:(NSString*)path error:(NSError **)error;
@end

@interface CBFrameFactory : NSObject
{
	NSArray * frameLoaders;
}

/*!
 Singleton accessor
 */
+ (CBFrameFactory*)factory;

+ (void)initialize;

- (id)init;

- (NSArray*)framesFromURL:(NSURL*)url error:(NSError **)error;
- (NSArray*)framesFromData:(NSData*)data withPath:(NSString*)path error:(NSError **)error;

@end
