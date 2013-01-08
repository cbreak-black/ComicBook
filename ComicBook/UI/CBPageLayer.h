//
//  CBPageLayer.h
//  ComicBook
//
//  Created by cbreak on 2012.12.23.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class CBFrame;

/*!
 \brief A layer representing an individual single page (or a double page) inside a comic view
 */
@interface CBPageLayer : CALayer
{
	CBFrame * comicBookFrame;
}

- (id)init;
- (id)initWithComicBookFrame:(CBFrame*)frame;

@property (nonatomic,retain) CBFrame * comicBookFrame;

@end
