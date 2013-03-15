//
//  CBFrameFactory.h
//  ComicBook
//
//  Created by cbreak on 2012.12.22.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CBFrameDataSource.h"

/*!
 \brief Frame loader base class
 */
@interface CBFrameLoader : NSObject
+ (CBFrameLoader*)loader;
- (BOOL)canLoadFramesFromURL:(NSURL*)url;
- (NSArray*)loadFramesFromURL:(NSURL*)url error:(NSError **)error;
- (BOOL)canLoadFramesFromDataSource:(id<CBFrameDataSource>)dataSource;
- (NSArray*)loadFramesFromDataSource:(id<CBFrameDataSource>)dataSource error:(NSError **)error;
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
- (NSArray*)framesFromDataSource:(id<CBFrameDataSource>)dataSource error:(NSError **)error;

@end
