//
//  CBPage.h
//  ComicBook
//
//  Created by cbreak on 04.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CBPage : NSObject
{

}

// To query image
@property (retain, readonly) NSImage * image;
@property (retain, readonly) NSString * path;

@end
