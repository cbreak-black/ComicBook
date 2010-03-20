//
//  CBURLPage.h
//  ComicBook
//
//  Created by cbreak on 04.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CBPage.h"

// A page backed from an URL, discardable and reloads from URL

@interface CBURLPage : CBPage
{
	NSURL * url;
	NSImage * img;

	NSUInteger accessCounter;
}

- (id)initWithURL:(NSURL *)imgURL;

@end
