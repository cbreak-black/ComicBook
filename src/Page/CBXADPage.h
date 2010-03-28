//
//  CBXADPage.h
//  ComicBook
//
//  Created by cbreak on 27.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CBPage.h"

@class XADArchiveParser;

// A page backed from a XAD archive, discardable and reloads from the archive file
@interface CBXADPage : CBPage
{
	XADArchiveParser * archive;
	NSDictionary * header;
}

- (id)initWithArchiveParser:(XADArchiveParser *)parser dictionary:(NSDictionary *)dict;

// Creation
+ (NSArray*)pagesFromArchiveURL:(NSURL*)archivePath;
+ (NSArray*)pagesFromArchiveData:(NSData*)archiveData withPath:(NSString*)archivePath;
+ (NSArray*)pagesFromArchiveParser:(XADArchiveParser*)archiveParser;

@end


// A page creator delegate class
@interface CBXADPageCreator : NSObject
{
	NSMutableArray * pages;
}

- (void)archiveParser:(XADArchiveParser *)parser foundEntryWithDictionary:(NSDictionary *)dict;
- (BOOL)archiveParsingShouldStop:(XADArchiveParser *)parser;
- (void)archiveParserNeedsPassword:(XADArchiveParser *)parser;

@property (readonly, retain) NSMutableArray * pages;

@end
