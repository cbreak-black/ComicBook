//
//  CBXADProxy.h
//  ComicBook
//
//  Created by cbreak on 2013.03.15.
//  Copyright (c) 2013 the-color-black.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XADArchiveParser;

@class CBXADArchiveFileProxy;
@class CBXADArchiveParserProxy;

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

@property (readonly) CBXADArchiveParserProxy * archiveParser;

@end

@interface CBXADArchiveParserProxy : NSObject
{
	CBXADArchiveParserProxy * baseArchive; // weak
	CBXADArchiveParserProxy * parentArchive;
	XADArchiveParser * archiveParser;
	BOOL parsed;
}

- (id)initWithArchiveParser:(XADArchiveParser*)archive parent:(CBXADArchiveParserProxy*)parent;
- (void)dealloc;

+ (CBXADArchiveParserProxy*)proxyWithArchiveParser:(XADArchiveParser*)archive parent:(CBXADArchiveParserProxy*)parent;
+ (CBXADArchiveParserProxy*)proxyWithArchiveFile:(CBXADArchiveFileProxy*)archiveFile;
+ (CBXADArchiveParserProxy*)proxyWithArchiveURL:(NSURL*)url;

@property (readonly) CBXADArchiveParserProxy * baseArchive;
@property (readonly) CBXADArchiveParserProxy * parentArchive;
@property (readonly) XADArchiveParser * archiveParser;

- (CBXADArchiveParserProxy*)getSubarchiveForEntry:(NSDictionary*)entry;
- (NSData*)getDataForEntry:(NSDictionary*)entry;

- (BOOL)needsParsing;
- (int)parseIfNeeded;
- (int)parse;
- (int)parseWithDelegate:(id)delegate;

+ (void)initialize;

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

@end
