//
//  CBDocument.m
//  ComicBook
//
//  Created by cbreak on 2012.12.15.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBDocument.h"

#import "CBComicWindowController.h"
#import "CBComicListController.h"

#import "CBComicModel.h"

@implementation CBDocument

- (id)init
{
    if (self = [super init])
	{
    }
    return self;
}

- (void)dealloc
{
	self.model = nil;
}

- (void)makeWindowControllers
{
	comicWindow = [[CBComicWindowController alloc] init];
	comicWindow.model = model;
	comicList = [[CBComicListController alloc] init];
	comicList.model = model;
	[self addWindowController:comicWindow];
	[self addWindowController:comicList];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName
			  error:(NSError **)outError
{
	self.model = [CBComicModel comicWithURL:url error:outError];
	return model != nil;
}

- (BOOL)isEntireFileLoaded
{
	return NO;
}

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName
{
	return YES;
}

- (void)close
{
	[model storePersistentData];
	[super close];
}

- (void)timedAutosave:(NSTimer*)timer
{
	if (timer == autosaveTimer)
	{
		autosaveTimer = nil;
		[model storePersistentData];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
						change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"currentFrameIdx"])
	{
		if (!autosaveTimer || ![autosaveTimer isValid])
		{
			autosaveTimer = [NSTimer scheduledTimerWithTimeInterval:60.0
				target:self selector:@selector(timedAutosave:) userInfo:nil repeats:NO];
		}
	}
}

- (void)setModel:(CBComicModel *)model_
{
	if (model != nil)
	{
		[model removeObserver:self forKeyPath:@"currentFrameIdx"];
	}
	model = model_;
	comicWindow.model = model;
	comicList.model = model;
	if (model != nil)
	{
		[model addObserver:self forKeyPath:@"currentFrameIdx" options:0 context:0];
	}
}

@synthesize model;

- (IBAction)toggleComicList:(id)sender
{
	if ([[comicList window] isVisible])
		[[comicList window] orderOut:sender];
	else
		[[comicList window] makeKeyAndOrderFront:sender];
}

@end
