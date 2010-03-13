//
//  CBDocumentController.m
//  ComicBook
//
//  Created by cbreak on 05.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBDocumentController.h"

// For View Settings
#import "CBCAView.h"

@implementation CBDocumentController

- (id)init
{
	self = [super init];
	if (self)
	{
		defaults = [[NSUserDefaults standardUserDefaults] retain];
		// Wait for notifications
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(defaultsChanged:)
													 name:NSUserDefaultsDidChangeNotification
												   object:defaults];
		modifying = NO;
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[defaults release];
	[super dealloc];
}

- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions
{
	[openPanel setCanChooseDirectories:YES];
	return [super runModalOpenPanel:openPanel forTypes:extensions];
}

// Document global settings

// Layout
- (BOOL)layoutSingle
{
	return [[defaults stringForKey:kCBLayoutKey] isEqualToString:kCBLayoutSingle];
}

- (BOOL)layoutLeft
{
	return [[defaults stringForKey:kCBLayoutKey] isEqualToString:kCBLayoutLeft];
}

- (BOOL)layoutRight
{
	return [[defaults stringForKey:kCBLayoutKey] isEqualToString:kCBLayoutRight];
}

- (void)setLayout:(NSString*)value
{
	modifying = YES;
	[self willChangeValueForKey:@"layoutSingle"];
	[self willChangeValueForKey:@"layoutLeft"];
	[self willChangeValueForKey:@"layoutRight"];
	[defaults setObject:value forKey:kCBLayoutKey];
	[self didChangeValueForKey:@"layoutSingle"];
	[self didChangeValueForKey:@"layoutLeft"];
	[self didChangeValueForKey:@"layoutRight"];
	modifying = NO;
}

- (void)setLayoutSingle:(BOOL)flag
{
	[self setLayout:kCBLayoutSingle];
}

- (void)setLayoutLeft:(BOOL)flag
{
	[self setLayout:kCBLayoutLeft];
}

- (void)setLayoutRight:(BOOL)flag
{
	[self setLayout:kCBLayoutRight];
}

// Scale
- (BOOL)scaleOriginal
{
	return [[defaults stringForKey:kCBScaleKey] isEqualToString:kCBScaleOriginal];
}

- (BOOL)scaleWidth
{
	return [[defaults stringForKey:kCBScaleKey] isEqualToString:kCBScaleWidth];
}

- (BOOL)scaleFull
{
	return [[defaults stringForKey:kCBScaleKey] isEqualToString:kCBScaleFull];
}

- (void)setScale:(NSString*)value
{
	modifying = YES;
	[self willChangeValueForKey:@"scaleOriginal"];
	[self willChangeValueForKey:@"scaleWidth"];
	[self willChangeValueForKey:@"scaleFull"];
	[defaults setObject:value forKey:kCBScaleKey];
	[self didChangeValueForKey:@"scaleOriginal"];
	[self didChangeValueForKey:@"scaleWidth"];
	[self didChangeValueForKey:@"scaleFull"];
	modifying = NO;
}

- (void)setScaleOriginal:(BOOL)flag
{
	[self setScale:kCBScaleOriginal];
}

- (void)setScaleWidth:(BOOL)flag
{
	[self setScale:kCBScaleWidth];
}

- (void)setScaleFull:(BOOL)flag
{
	[self setScale:kCBScaleFull];
}

- (void)defaultsChanged:(NSNotification*)notification
{
	if (!modifying)
	{
		// Layout
		[self willChangeValueForKey:@"layoutSingle"];
		[self didChangeValueForKey:@"layoutSingle"];
		[self willChangeValueForKey:@"layoutLeft"];
		[self didChangeValueForKey:@"layoutLeft"];
		[self willChangeValueForKey:@"layoutRight"];
		[self didChangeValueForKey:@"layoutRight"];
		// Scale
		[self willChangeValueForKey:@"scaleOriginal"];
		[self didChangeValueForKey:@"scaleOriginal"];
		[self willChangeValueForKey:@"scaleWidth"];
		[self didChangeValueForKey:@"scaleWidth"];
		[self willChangeValueForKey:@"scaleFull"];
		[self didChangeValueForKey:@"scaleFull"];
	}
}

@end
