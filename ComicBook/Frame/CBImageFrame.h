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

+ (id<CBFrameLoader>)loader;

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

+ (id<CBFrameLoader>)loader;

@end
