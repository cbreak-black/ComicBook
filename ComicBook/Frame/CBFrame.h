//
//  CBFrame.h
//  ComicBook
//
//  Created by cbreak on 2012.12.22.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CBFrameFactory.h"
#import "CBFrameDataSource.h"

@interface CBFrame : NSObject
{
	NSMutableString * filteredPath;
}

// Designated initializer
- (id)init;

/*!
 Return the image of this frame, loading it if required
 */
@property (retain, readonly) NSImage * image;

/*!
 Return the path of this frame
 */
@property (retain, readonly) NSString * path;

/*!
 Return the filtered and cleaned path of this frame, things inside brackets are removed
 */
@property (retain, readonly) NSString * filteredPath;

/*!
 Filters the path of this frame, removing things in brackets, and the root path. The filtered path
 is also available in the filteredPath property.
 */
- (NSString*)filterPathWithRoot:(NSString*)rootPath;

@end
