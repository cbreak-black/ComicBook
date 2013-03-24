//
//  CBComicListController.m
//  ComicBook
//
//  Created by cbreak on 2013.03.24.
//  Copyright (c) 2013 the-color-black.net. All rights reserved.
//

#import "CBComicListController.h"

#import "CBComicModel.h"

@implementation CBComicListController

- (id)init
{
	if (self = [super initWithWindowNibName:@"CBComicList"])
	{
	}
	return self;
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	if (model && frameController)
	{
		[frameController setSelectionIndex:model.currentFrameIdx];
		[frameController setAvoidsEmptySelection:YES];
	}
}

- (void)setModel:(CBComicModel *)model_
{
	model = model_;
	if (model && frameController)
		[frameController setSelectionIndexes:model.currentFrameSet];
}

@synthesize model;

@end
