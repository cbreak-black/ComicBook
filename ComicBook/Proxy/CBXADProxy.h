//
//  CBXADProxy.h
//  ComicBook
//
//  Created by cbreak on 2013.03.15.
//  Copyright (c) 2013 the-color-black.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XADArchiveParser;

@interface CBXADArchiveFileProxy : NSObject
{
	NSURL * baseURL;
	NSArray * entries;
}

- (id)initWithURL:(NSURL*)baseURL entry:(NSDictionary*)entry;
- (id)initWithURL:(NSURL*)baseURL entries:(NSArray*)entries;
- (void)dealloc;

@property (readonly) NSString * path;
@property (readonly) NSData * data;

@property (readonly) NSURL * baseURL;
@property (readonly) NSArray * entries; //!< All entries, identifying files in the archive chain
@property (readonly) NSDictionary * entry; //!< The last entry, identifying the file in the archive

/*!
 The archive parsers, the first is the root file, all others are contained archives. The entry refers
 to the last archive.
 */
@property (readonly) NSArray * archiveParser;

@end

/*!
 \brief Isolates non-arc compliant code from XADMaster from normal code
 */
@interface CBXADProxy : NSObject

+ (void)initialize;

+ (BOOL)canLoadArchiveAtURL:(NSURL*)url;
+ (BOOL)loadArchiveAtURL:(NSURL*)url
			   withBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback;

+ (BOOL)canLoadArchiveFromArchiveFile:(CBXADArchiveFileProxy*)archiveFile;
+ (BOOL)loadArchiveFromArchiveFile:(CBXADArchiveFileProxy*)archiveFile
						 withBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback;

@end
