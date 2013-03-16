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
	NSDictionary * entry;
	XADArchiveParser * archive;
}

- (id)initWithEntry:(NSDictionary*)entry inArchive:(XADArchiveParser*)archive;
- (void)dealloc;

@property (readonly) NSString * path;
@property (readonly) NSData * data;

@property (readonly) NSDictionary * entry;
@property (readonly) XADArchiveParser * archive;

@end

/*!
 \brief Isolates non-arc compliant code from XADMaster from normal code
 */
@interface CBXADProxy : NSObject

+ (BOOL)canLoadArchiveAtURL:(NSURL*)url;
+ (NSArray*)loadArchiveAtURL:(NSURL*)url error:(NSError **)error;

+ (BOOL)canLoadArchiveFromArchiveFile:(CBXADArchiveFileProxy*)archiveFile;
+ (NSArray*)loadArchiveFromArchiveFile:(CBXADArchiveFileProxy*)archiveFile error:(NSError **)error;

+ (NSArray*)loadArchiveFromParser:(XADArchiveParser*)parser error:(NSError **)error;

@end
