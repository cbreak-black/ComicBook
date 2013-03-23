//
//  CBFrame.m
//  ComicBook
//
//  Created by cbreak on 2012.12.22.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBFrame.h"

@implementation CBFrame

- (id)init
{
	if (self = [super init])
	{
	}
	return self;
}

- (NSImage*)image
{
	// TODO: Return placeholder image
	return nil;
}

- (NSString*)path
{
	return @"";
}

@synthesize filteredPath;

static NSString * empty = @"";
static NSString * bracketPatterns[] = {
	@"[ _]*+\\[.*?\\][ _]*+",
	@"[ _]*+\\(.*?\\)[ _]*+",
	@"[ _]*+\\{.*?\\}[ _]*+"
};

- (NSString*)filterPathWithRoot:(NSString*)rootPath
{
	filteredPath = [self.path mutableCopy];
	[filteredPath replaceOccurrencesOfString:rootPath withString:empty
		options:NSAnchoredSearch range:NSMakeRange(0, [filteredPath length])];
	// Remove stuff in bracketed things
	for (NSUInteger i = 0; i < sizeof(bracketPatterns)/sizeof(NSString*); ++i)
	{
		[filteredPath replaceOccurrencesOfString:bracketPatterns[i] withString:empty
			options:NSRegularExpressionSearch range:NSMakeRange(0, [filteredPath length])];
	}
	return filteredPath;
}

@end
