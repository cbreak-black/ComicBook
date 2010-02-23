//
//  ComicBookGLView.h
//
//  Created by cbreak on 23.02.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ComicBookGLView : NSOpenGLView
{

}

// Redraw the view
- (void)drawRect:(NSRect)dirtyRect;

// Adjust view / Initialize
- (void)adjustViewport;
- (void)prepareOpenGL; // initialize

@end
