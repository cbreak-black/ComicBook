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
	id<CBFrameDataSource> dataSource;
}

- (id)initWithDataSource:(id<CBFrameDataSource>)dataSource;

@property (retain, readonly) NSString * path;
@property (retain, readonly) NSImage * image;

@end

/*!
 \brief Load Image Frames
 */
@interface CBImageFrameLoader : CBFrameLoader
- (BOOL)canLoadFramesFromURL:(NSURL*)url;
- (BOOL)loadFramesFromURL:(NSURL*)url withBlock:(void (^)(CBFrame*))frameCallback;
- (BOOL)canLoadFramesFromDataSource:(id<CBFrameDataSource>)dataSource;
- (BOOL)loadFramesFromDataSource:(id<CBFrameDataSource>)dataSource withBlock:(void (^)(CBFrame*))frameCallback;
@end
