//
//  CBComicWindowController.m
//  ComicBook
//
//  Created by cbreak on 2012.12.23.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBComicWindowController.h"

#import "CBComicView.h"
#import "CBComicModel.h"

@implementation CBComicWindowController

- (id)init
{
	if (self = [super initWithWindowNibName:@"CBComicWindow"])
	{
		[self setShouldCloseDocument:YES];
	}
	return self;
}

- (void)dealloc
{
	model = nil;
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	[[self window] setInitialFirstResponder:comicView];
	[self startLoading];
	comicView.model = model;
}

- (void)setModel:(CBComicModel *)model_
{
	if (model != nil)
	{
		[model removeObserver:self forKeyPath:@"framesLoaded"];
	}
	model = model_;
	if (comicView)
		comicView.model = model;
	if (model != nil)
	{
		[model addObserver:self forKeyPath:@"framesLoaded"
				   options:NSKeyValueObservingOptionInitial context:0];
	}
}

@synthesize model;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
						change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"framesLoaded"])
	{
		if (model.framesLoaded)
		{
			[self stopLoading];
		}
	}
}

- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)code context:(void*)context
{
	[sheet orderOut:self];
}

- (void)startLoading
{
	[loadingIndicator startAnimation:self];
	[NSApp beginSheet:loadingSheet modalForWindow:self.window
		modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:context:) contextInfo:0];
}

- (void)stopLoading
{
	[NSApp endSheet:loadingSheet];
	[loadingIndicator stopAnimation:self];
}

@end
