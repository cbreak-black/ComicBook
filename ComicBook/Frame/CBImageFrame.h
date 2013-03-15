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
- (BOOL)canLoadFramesFromDataSource:(id<CBFrameDataSource>)dataSource;
- (NSArray*)loadFramesFromDataSource:(id<CBFrameDataSource>)dataSource error:(NSError **)error;
@end
