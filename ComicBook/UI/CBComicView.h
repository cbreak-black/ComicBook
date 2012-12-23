//
//  CBComicView.h
//  ComicBook
//
//  Created by cbreak on 2012.12.23.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <Quartz/Quartz.h>

/*!
 \brief The view hosting the layers that represent the comic
 */
@interface CBComicView : NSView
{
	CALayer * backgroundLayer;
}

@end
