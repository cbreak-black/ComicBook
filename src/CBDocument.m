//
//  CBDocument.m
//  ComicBook
//
//  Created by cbreak on 01.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBDocument.h"

#import "Controllers/CBListController.h"
#import "Controllers/CBPageController.h"

#import "CBPage.h"
#import "CBURLPage.h"

@implementation CBDocument

- (id)init
{
	self = [super init];
	if (self)
	{
		pages = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[listController release];
	[pageController release];
	[pages release];
	[baseURL release];
	[super dealloc];
}

- (void)makeWindowControllers
{
	CBListController * lc = [[CBListController alloc] init];
	CBPageController * pc = [[CBPageController alloc] init];
	[self setListController:lc];
	[self setPageController:pc];
	[self addWindowController:lc];
	[self addWindowController:pc];
	[lc release];
	[pc release];
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	if ( outError != NULL )
	{
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	NSNumber * isDirectory;
	[absoluteURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
	if ([isDirectory boolValue])
	{
		if (baseURL != absoluteURL)
		{
			[baseURL release];
			baseURL = [absoluteURL retain];
		}
		[self addDirectoryURL:absoluteURL];
	}
	else
	{
		[baseURL release];
		baseURL = [[absoluteURL URLByDeletingLastPathComponent] retain];
		[self addFileURL:absoluteURL];
	}
	[listController documentUpdated];
    return YES;
}

// Add files
- (void)addDirectoryURL:(NSURL *)url
{
	NSFileManager * fm = [[NSFileManager alloc] init];
	NSDirectoryEnumerator * de =
		[fm enumeratorAtURL:url includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLTypeIdentifierKey,NSURLIsDirectoryKey,nil]
					options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:^(NSURL *url, NSError *error)
	{
		NSLog(@"addDirectoryURL enumerator error: %@", error);
		return YES;
	}];
	for (NSURL * url in de)
	{
		NSNumber * isDirectory;
		if ([url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL])
		{
			if (![isDirectory boolValue]) // Some kind of file
			{
				[self addFileURL:url];
			};
		};
	};
	[fm release];
	[pages sortWithOptions:NSSortConcurrent usingComparator:^(id o1, id o2){return [[o1 path] localizedStandardCompare:[o2 path]];}];
}

- (void)addFileURL:(NSURL *)url
{
	CBPage * page = [[CBURLPage alloc] initWithURL:url];
	if (page)
	{
		[pages addObject:page];
		[page release];
	}
}

// Page access
- (NSInteger)pageCount
{
	return [pages count];
}

- (CBPage *)getPage:(NSInteger)number
{
	return (CBPage *)[pages objectAtIndex:number];
}


@synthesize listController;
@synthesize pageController;
@synthesize baseURL;

@end
