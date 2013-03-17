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
	XADArchiveParser * master;
}

- (id)initWithEntry:(NSDictionary*)entry inArchive:(XADArchiveParser*)archive;
- (id)initWithEntry:(NSDictionary*)entry inArchive:(XADArchiveParser*)archive
								 withMasterArchive:(XADArchiveParser*)master;
- (void)dealloc;

@property (readonly) NSString * path;
@property (readonly) NSData * data;

@property (readonly) NSDictionary * entry;
@property (readonly) XADArchiveParser * archive;
@property (readonly) XADArchiveParser * master;

@end

/*!
 \brief Isolates non-arc compliant code from XADMaster from normal code
 */
@interface CBXADProxy : NSObject

+ (BOOL)canLoadArchiveAtURL:(NSURL*)url;
+ (BOOL)loadArchiveAtURL:(NSURL*)url
			   withBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback;

+ (BOOL)canLoadArchiveFromArchiveFile:(CBXADArchiveFileProxy*)archiveFile;
+ (BOOL)loadArchiveFromArchiveFile:(CBXADArchiveFileProxy*)archiveFile
						 withBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback;

+ (BOOL)loadArchiveFromParser:(XADArchiveParser*)parser
					withBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback;
+ (BOOL)loadArchiveFromParser:(XADArchiveParser*)parser master:(XADArchiveParser*)master
					withBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback;

@end
