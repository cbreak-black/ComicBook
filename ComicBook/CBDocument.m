//
//  CBDocument.m
//  ComicBook
//
//  Created by cbreak on 2012.12.15.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBDocument.h"

#import "CBComicWindowController.h"

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
	[self addWindowController:comicWindow];
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
	if ([keyPath isEqualToString:@"currentFrame"])
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
		[model removeObserver:self forKeyPath:@"currentFrame"];
	}
	model = model_;
	if (model != nil)
	{
		[model addObserver:self forKeyPath:@"currentFrame" options:0 context:0];
	}
}

@synthesize model;

@end
