//
//  CBFrameFactory.h
//  ComicBook
//
//  Created by cbreak on 2012.12.22.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CBFrameFactory : NSObject
{
	NSArray * frameLoaders;
}

/*!
 Singleton accessor
 */
+ (CBFrameFactory*)factory;

- (id)init;

- (NSArray*)framesFromURL:(NSURL*)url error:(NSError **)error;

- (NSArray*)framesFromDirectoryURL:(NSURL*)url error:(NSError **)error;
- (NSArray*)framesFromFileURL:(NSURL*)url error:(NSError **)error;
- (NSArray*)framesFromData:(NSData*)data withPath:(NSString*)path error:(NSError **)error;

@end
