//
//  CBImageFrame.h
//  ComicBook
//
//  Created by cbreak on 2012.12.22.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBFrame.h"

/*!
 \brief Load image from an URL
 */
@interface CBURLImageFrame : CBFrame
{
	NSURL * url;
}

- (id)initWithURL:(NSURL*)frameURL;

@property (retain, readonly) NSString * path;
@property (retain, readonly) NSImage * image;

@end

/*!
 \brief Load images from Data
 */
@interface CBDataImageFrame : CBFrame
{
	NSData * data;
	NSString * path;
}

- (id)initWithData:(NSData*)data withPath:(NSString*)path;

@property (retain, readonly) NSString * path;
@property (retain, readonly) NSImage * image;

@end

/*!
 \brief Load URL Image Frames
 */
@interface CBURLImageFrameLoader : CBFrameLoader
- (BOOL)canLoadFramesFromURL:(NSURL*)url;
- (NSArray*)loadFramesFromURL:(NSURL*)url error:(NSError **)error;
@end

/*!
 \brief Load Data Image Frames
 */
@interface CBDataImageFrameLoader : CBFrameLoader
- (BOOL)canLoadFramesFromData:(NSData*)data withPath:(NSString*)path;
- (NSArray*)loadFramesFromData:(NSData*)data withPath:(NSString*)path error:(NSError **)error;
@end
