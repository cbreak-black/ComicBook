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

@interface CBZipPage : CBPage
{
	ZKDataArchive * archive;
	ZKCDHeader * header;
	NSImage * img;

	NSUInteger accessCounter;
}

- (id)initWithArchive:(ZKDataArchive *)fileArchive header:(ZKCDHeader*)fileHeader;

// Creation
+ (NSArray*)pagesFromZipFile:(NSURL*)zipPath;

@end
