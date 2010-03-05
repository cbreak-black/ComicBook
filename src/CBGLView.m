//
//  CBGLView.m
//
//  Created by cbreak on 23.02.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBGLView.h"

@implementation CBGLView

- (id)initWithFrame:(NSRect)frame
{
	NSOpenGLPixelFormatAttribute attrs[] =
	{
		NSOpenGLPFAColorSize, 32,
		NSOpenGLPFAAccelerated,
		NSOpenGLPFANoRecovery,
		NSOpenGLPFADoubleBuffer,
		0
	};
	NSOpenGLPixelFormat* pixFmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];

	self = [super initWithFrame:frame pixelFormat:pixFmt];
    if (self)
	{
	}
	[pixFmt release];
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[[self openGLContext] makeCurrentContext];

	glClear(GL_COLOR_BUFFER_BIT);

	// Test Pattern
	glColor4f(0.0f, 0.0f, 0.0f, 1.0f);
	glBegin(GL_LINES);
	glVertex3f(0.0f, 0.0f, 0.0f);
	glVertex3f(1.0f, 1.0f, 0.0f);
	glVertex3f(1.0f, 0.0f, 0.0f);
	glVertex3f(0.0f, 1.0f, 0.0f);
	glEnd();

	[[self openGLContext] flushBuffer];
}

// moved or resized
- (void)update
{
	[super update];
	[self adjustViewport];
}

// scrolled, moved or resized
- (void)reshape
{
	[super reshape];
	[self adjustViewport];
}

- (void)adjustViewport
{
	NSRect bounds = [self bounds];
	glViewport(bounds.origin.x, bounds.origin.y,
			   bounds.size.width, bounds.size.height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(0.0f, 1.0f, 0.0f, bounds.size.height/bounds.size.width, -1.0f, 1.0f);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
}

- (void)prepareOpenGL
{
	glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
}

@end
