//
//  CBPageController.m
//  ComicBook
//
//  Created by cbreak on 02.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBPageController.h"


@implementation CBPageController

- (id)init
{
	self = [super initWithWindowNibName:@"CBPage"];
	if (self)
	{
		[self setShouldCloseDocument:YES];
	}
	return self;
}

@end
