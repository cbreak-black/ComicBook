//
//  CBDataPage.h
//  ComicBook
//
//  Created by cbreak on 20.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CBPage.h"

// A page made from data, NOT discardable, only use when other methods don't work

@interface CBDataPage : CBPage
{
	NSString * path;
	NSImage * img;
}

- (id)initWithImageData:(NSData*)imgData withPath:(NSString*)imgPath;

// Creation (Returns an array with one or zero pages)
+ (NSArray*)pagesFromImageData:(NSData*)imgData withPath:(NSString*)imgPath;

@end
