//
//  CBZipPage.h
//  ComicBook
//
//  Created by cbreak on 19.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CBPage.h"

@class ZKDataArchive;
@class ZKCDHeader;

// A page backed from a ZipKit archive, discardable and reloads from the zip file

@interface CBZipPage : CBPage
{
	ZKDataArchive * archive;
	ZKCDHeader * header;
}

- (id)initWithArchive:(ZKDataArchive *)fileArchive header:(ZKCDHeader*)fileHeader;

// Creation
// File based uses mmaped IO, so it's faster and uses less memory
+ (NSArray*)pagesFromZipFile:(NSURL*)zipPath;
+ (NSArray*)pagesFromZipData:(NSMutableData*)zipData withPath:(NSString*)zipPath;

@end
