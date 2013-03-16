//
//  CBXADFrame.h
//  ComicBook
//
//  Created by cbreak on 2013.03.15.
//  Copyright (c) 2013 the-color-black.net. All rights reserved.
//

#import "CBFrame.h"

@class CBXADArchiveFileProxy;

@interface CBXADFrameDataSource : NSObject<CBFrameDataSource>
{
	CBXADArchiveFileProxy * archive;
}

- (id)initWithXADArchive:(CBXADArchiveFileProxy*)archive;

@property (readonly) NSData * frameData;
@property (readonly) NSString * framePath;

@end

/*!
 \brief Load frames in compressed archives
 */
@interface CBXADFrameLoader : CBFrameLoader
- (BOOL)canLoadFramesFromURL:(NSURL*)url;
- (BOOL)loadFramesFromURL:(NSURL*)url withBlock:(void (^)(CBFrame*))frameCallback;
- (BOOL)canLoadFramesFromDataSource:(id<CBFrameDataSource>)dataSource;
- (BOOL)loadFramesFromDataSource:(id<CBFrameDataSource>)dataSource withBlock:(void (^)(CBFrame*))frameCallback;

- (BOOL)framesFromArchiveFile:(CBXADArchiveFileProxy*)archiveFile withBlock:(void (^)(CBFrame*))frameCallback;
@end
