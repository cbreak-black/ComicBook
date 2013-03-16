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
- (NSArray*)loadFramesFromURL:(NSURL*)url error:(NSError **)error;
- (BOOL)canLoadFramesFromData:(NSData*)data withPath:(NSString*)path;
- (NSArray*)loadFramesFromData:(NSData*)data withPath:(NSString*)path error:(NSError **)error;

- (NSArray*)framesFromArchiveFile:(CBXADArchiveFileProxy*)archiveFile;
- (NSArray*)framesFromArchiveFiles:(NSArray*)archiveFiles;
@end
