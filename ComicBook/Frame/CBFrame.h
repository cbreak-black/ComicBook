//
//  CBFrame.h
//  ComicBook
//
//  Created by cbreak on 2012.12.22.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CBFrameLoader
- (BOOL)canLoadFramesFromURL:(NSURL*)url;
- (NSArray*)loadFramesFromURL:(NSURL*)url;
- (BOOL)canLoadFramesFromData:(NSData*)data withPath:(NSString*)path;
- (NSArray*)loadFramesFromData:(NSData*)data withPath:(NSString*)path;
@end

@interface CBFrame : NSObject
{
}

// Designated initializer
- (id)init;

/*!
 Return the path of this frame
 */
@property (retain, readonly) NSString * path;

/*!
 Return the image of this frame, loading it if required
 */
@property (retain, readonly) NSImage * image;

/*!
 Return a loader for that frame type
 */
+ (id<CBFrameLoader>)loader;

@end
