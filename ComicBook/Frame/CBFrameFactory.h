//
//  CBFrameFactory.h
//  ComicBook
//
//  Created by cbreak on 2012.12.22.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CBFrameDataSource.h"

@class CBFrame;

/*!
 \brief Frame loader base class
 */
@interface CBFrameLoader : NSObject
+ (CBFrameLoader*)loader;
- (BOOL)canLoadFramesFromURL:(NSURL*)url;
- (BOOL)loadFramesFromURL:(NSURL*)url withBlock:(void (^)(CBFrame*))frameCallback;
- (BOOL)canLoadFramesFromDataSource:(id<CBFrameDataSource>)dataSource;
- (BOOL)loadFramesFromDataSource:(id<CBFrameDataSource>)dataSource withBlock:(void (^)(CBFrame*))frameCallback;
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

- (BOOL)framesFromURL:(NSURL*)url withBlock:(void (^)(CBFrame*))frameCallback;
- (BOOL)framesFromDataSource:(id<CBFrameDataSource>)dataSource withBlock:(void (^)(CBFrame*))frameCallback;

@end
