//
//  CBXADProxy.m
//  ComicBook
//
//  Created by cbreak on 2013.03.15.
//  Copyright (c) 2013 the-color-black.net. All rights reserved.
//

#import "CBXADProxy.h"

#import <XADMaster/XADArchiveParser.h>
#import <XADMaster/XADException.h>

static XADArchiveParser * getCachedArchiveParserForPath(NSString * path);

// Archive File Proxy
@implementation CBXADArchiveFileProxy

- (id)initWithURL:(NSURL*)baseURL_ entry:(NSDictionary*)entry
{
	if (self = [super init])
	{
		baseURL = [baseURL_ retain];
		entries = [[NSArray arrayWithObject:entry] retain];
	}
	return self;
}

- (id)initWithURL:(NSURL*)baseURL_ entries:(NSArray*)entries_
{
	if (self = [super init])
	{
		assert([entries_ count] > 0);
		baseURL = [baseURL_ retain];
		entries = [entries_ retain];
	}
	return self;
}

- (void)dealloc
{
	[entries release];
	[baseURL release];
	[super dealloc];
}

- (NSString*)path
{
	NSURL * fullURL = baseURL;
	for (NSDictionary * entry in entries)
	{
		fullURL = [fullURL URLByAppendingPathComponent:[[entry objectForKey:XADFileNameKey] string]];
	}
	return [fullURL path];
}

- (NSData*)data
{
	@try
	{
		NSArray * archiveParserChain = [self archiveParser];
		if (archiveParserChain)
		{
			@synchronized([archiveParserChain objectAtIndex:0])
			{
				XADArchiveParser * archive = [archiveParserChain lastObject];
				CSHandle * dataHandle = [archive handleForEntryWithDictionary:[entries lastObject] wantChecksum:YES];
				return [dataHandle remainingFileContents];
			}
		}
	}
	@catch (NSException * e)
	{
		NSLog(@"Exception %@ reading archive at path %@", e, [self path]);
	}
	return nil;
}

- (NSArray*)archiveParser
{
	@try
	{
		NSMutableArray * archiveParserChain = [NSMutableArray arrayWithCapacity:8];
		XADArchiveParser * archive = getCachedArchiveParserForPath([baseURL path]);
		[archiveParserChain addObject:archive];
		@synchronized(archive)
		{
			for (NSUInteger entryIdx = 0; entryIdx < [entries count]-1; ++entryIdx)
			{
				archive = [XADArchiveParser archiveParserForEntryWithDictionary:[entries objectAtIndex:entryIdx]
																  archiveParser:archive wantChecksum:YES];
				[archiveParserChain addObject:archive];
			}
		}
		return archiveParserChain;
	}
	@catch (NSException * e)
	{
		NSLog(@"Exception %@ opening archive at path %@", e, [self path]);
	}
	return nil;
}

@synthesize baseURL;
@synthesize entries;

- (NSDictionary*)entry
{
	return [entries lastObject];
}


@end

// Delegate for parsing
@interface CBXADParserDelegate : NSObject
{
	void (^fileCallback)(CBXADArchiveFileProxy*);
	NSURL * baseURL;
	NSArray * entries;
	NSMutableArray * files;
}

- (id)initWithBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback forURL:(NSURL*)baseURL;
- (id)initWithBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback forURL:(NSURL*)baseURL
			entries:(NSArray*)entries;

- (void)commit;

- (void)archiveParser:(XADArchiveParser *)parser foundEntryWithDictionary:(NSDictionary *)dict;
- (BOOL)archiveParsingShouldStop:(XADArchiveParser *)parser;
- (void)archiveParserNeedsPassword:(XADArchiveParser *)parser;
- (void)archiveParser:(XADArchiveParser *)parser findsFileInterestingForReason:(NSString *)reason;

@end

@implementation CBXADParserDelegate

- (id)initWithBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback_ forURL:(NSURL*)baseURL_
{
	return [self initWithBlock:fileCallback_ forURL:baseURL_ entries:nil];
}

- (id)initWithBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback_ forURL:(NSURL*)baseURL_ entries:(NSArray*)entries_
{
	if (self = [super init])
	{
		fileCallback = [fileCallback_ retain];
		baseURL = [baseURL_ retain];
		if (entries_ == nil)
			entries = [[NSArray alloc] init];
		else
			entries = [entries_ retain];
		files = [[NSMutableArray alloc] initWithCapacity:32];
	}
	return self;
}

- (void)dealloc
{
	[files release];
	[entries release];
	[baseURL release];
	[fileCallback release];
	[super dealloc];
}

- (void)commit
{
	// Sort
	[files sortUsingComparator:^(CBXADArchiveFileProxy * a, CBXADArchiveFileProxy * b)
	{ return [a.path compare:b.path options:NSNumericSearch|NSCaseInsensitiveSearch]; }];
	// Notify with callback
	for (CBXADArchiveFileProxy * archiveFile in files)
	{
		fileCallback(archiveFile);
	}
	[files removeAllObjects];
}

- (void)archiveParser:(XADArchiveParser *)parser foundEntryWithDictionary:(NSDictionary *)dict
{
	if (![[dict objectForKey:XADIsDirectoryKey] boolValue] &&
		![[dict objectForKey:XADIsResourceForkKey] boolValue] &&
		![[dict objectForKey:XADIsLinkKey] boolValue] &&
		![[dict objectForKey:XADIsHardLinkKey] boolValue] &&
		![[dict objectForKey:XADIsCharacterDeviceKey] boolValue] &&
		![[dict objectForKey:XADIsBlockDeviceKey] boolValue] &&
		![[dict objectForKey:XADIsFIFOKey] boolValue])
	{
		NSArray * subEntries = [entries arrayByAddingObject:dict];
		CBXADArchiveFileProxy * archiveFile = [[CBXADArchiveFileProxy alloc] initWithURL:baseURL entries:subEntries];
		[files addObject:archiveFile];
		[archiveFile release];
	}
}

- (BOOL)archiveParsingShouldStop:(XADArchiveParser *)parser
{
	return NO;
}

- (void)archiveParserNeedsPassword:(XADArchiveParser *)parser
{
	NSLog(@"Archive \"%@\" needs password", [parser filename]);
}

- (void)archiveParser:(XADArchiveParser *)parser findsFileInterestingForReason:(NSString *)reason
{
	NSLog(@"Archive \"%@\" contains interesting file: %@", [parser filename], reason);
}

@end

// Cache
static NSCache * archiveFileCache = nil; // Initialized by +[CBXADProxy initialize]

static XADArchiveParser * getCachedArchiveParserForPath(NSString * path)
{
	XADArchiveParser * archive = [archiveFileCache objectForKey:path];
	if (archive)
		return archive;
	XADError error = XADNoError;
	archive = [XADArchiveParser archiveParserForPath:path error:&error];
	if (archive && error == XADNoError)
	{
		[archiveFileCache setObject:archive forKey:path];
		return archive;
	}
	return nil;
}

// Proxy
@implementation CBXADProxy

+ (void)initialize
{
	if (archiveFileCache == nil)
	{
		archiveFileCache = [[NSCache alloc] init];
		archiveFileCache.countLimit = 128;
		archiveFileCache.name = @"Archive Parser Cache";
	}
}

+ (BOOL)canLoadArchiveAtURL:(NSURL*)url
{
	@autoreleasepool
	{
		return getCachedArchiveParserForPath([url path]) != nil;
	}
}

+ (BOOL)loadArchiveAtURL:(NSURL*)url
			   withBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback
{
	@autoreleasepool
	{
		XADError error = XADNoError;
		XADArchiveParser * parser = getCachedArchiveParserForPath([url path]);
		if (parser && error == XADNoError)
		{
			CBXADParserDelegate * delegate = [[CBXADParserDelegate alloc]
											  initWithBlock:fileCallback forURL:url];
			[parser setDelegate:delegate];
			error = [parser parseWithoutExceptions];
			[delegate commit];
			[delegate release];
			return error == XADNoError;
		}
		return NO;
	}
}

+ (BOOL)canLoadArchiveFromArchiveFile:(CBXADArchiveFileProxy*)archiveFile
{
	@autoreleasepool
	{
		XADError error = XADNoError;
		NSArray * archiveParserChain = [archiveFile archiveParser];
		XADArchiveParser * parser = [XADArchiveParser archiveParserForEntryWithDictionary:[archiveFile entry]
			archiveParser:[archiveParserChain lastObject] wantChecksum:NO error:&error];
		return (parser && error == XADNoError);
	}
}

+ (BOOL)loadArchiveFromArchiveFile:(CBXADArchiveFileProxy*)archiveFile
						 withBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback
{
	@autoreleasepool
	{
		XADError error = XADNoError;
		NSArray * archiveParserChain = [archiveFile archiveParser];
		XADArchiveParser * parser = [XADArchiveParser archiveParserForEntryWithDictionary:[archiveFile entry]
			archiveParser:[archiveParserChain lastObject] wantChecksum:NO error:&error];
		if (parser && error == XADNoError)
		{
			if ([parser filename] == nil)
				[parser setFilename:[archiveFile path]];
			CBXADParserDelegate * delegate = [[CBXADParserDelegate alloc]
					initWithBlock:fileCallback forURL:[archiveFile baseURL] entries:[archiveFile entries]];
			[parser setDelegate:delegate];
			error = [parser parseWithoutExceptions];
			[delegate commit];
			[delegate release];
			return error == XADNoError;
		}
		return NO;
	}
}

@end
