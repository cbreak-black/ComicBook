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
		CBXADArchiveParserProxy * archiveParser = [self archiveParser];
		if (archiveParser)
		{
			return [archiveParser getDataForEntry:[entries lastObject]];
		}
	}
	@catch (NSException * e)
	{
		NSLog(@"Exception %@ reading archive at path %@", e, [self path]);
	}
	return nil;
}

- (CBXADArchiveParserProxy*)archiveParser
{
	@try
	{
		CBXADArchiveParserProxy * proxy = [CBXADArchiveParserProxy proxyWithArchiveURL:baseURL];
		for (NSUInteger entryIdx = 0; entryIdx < [entries count]-1; ++entryIdx)
		{
			proxy = [proxy getSubarchiveForEntry:[entries objectAtIndex:entryIdx]];
		}
		return proxy;
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

// Archive Parser Proxy

// Archive Parser Proxy global state
// Initialized by +[CBXADArchiveParserProxy initialize]
static NSCache * archiveParserProxyCache = nil;
static NSArray * archiveExtensionBlacklist = nil;

@implementation CBXADArchiveParserProxy : NSObject

- (id)initWithArchiveParser:(XADArchiveParser*)archive_ parent:(CBXADArchiveParserProxy*)parent_
{
	if (self = [super init])
	{
		if (parent_)
		{
			baseArchive = [parent_ baseArchive];
			parentArchive = [parent_ retain];
		}
		else
		{
			baseArchive = self;
			parentArchive = nil;
		}
		archiveParser = [archive_ retain];
		// Some parsers don't need to be parsed before using entry dicts
		if ([archiveParser isKindOfClass:NSClassFromString(@"XADZipParser")] ||
			[archiveParser isKindOfClass:NSClassFromString(@"XADRARParser")])
		{
			parsed = YES;
		}
		else
		{
			parsed = NO;
		}
	}
	return self;
}

- (void)dealloc
{
	[archiveParser release];
	[parentArchive release];
	// baseArchive is weak
	[super dealloc];
}

+ (CBXADArchiveParserProxy*)proxyWithArchiveParser:(XADArchiveParser*)archive parent:(CBXADArchiveParserProxy*)parent;
{
	CBXADArchiveParserProxy * proxy = [[CBXADArchiveParserProxy alloc] initWithArchiveParser:archive parent:parent];
	return [proxy autorelease];
}

+ (CBXADArchiveParserProxy*)proxyWithArchiveURL:(NSURL*)url
{
	NSString * extension = [url pathExtension];
	if ([[CBXADArchiveParserProxy archiveExtensionBlacklist] containsObject:extension])
		return nil;
	CBXADArchiveParserProxy * proxy = [archiveParserProxyCache objectForKey:url];
	if (proxy)
		return proxy;
	XADError error = XADNoError;
	XADArchiveParser * archive = [XADArchiveParser archiveParserForPath:[url path] error:&error];
	if (archive && error == XADNoError)
	{
		proxy = [CBXADArchiveParserProxy proxyWithArchiveParser:archive parent:nil];
		[archiveParserProxyCache setObject:proxy forKey:url];
		return proxy;
	}
	return nil;
}

+ (CBXADArchiveParserProxy*)proxyWithArchiveFile:(CBXADArchiveFileProxy*)archiveFile
{
	CBXADArchiveParserProxy * archiveParserProxy = [archiveFile archiveParser];
	return [archiveParserProxy getSubarchiveForEntry:[archiveFile entry]];
}

@synthesize baseArchive;
@synthesize parentArchive;
@synthesize archiveParser;

- (CBXADArchiveParserProxy*)getSubarchiveForEntry:(NSDictionary*)entry
{
	NSString * extension = [[[entry objectForKey:XADFileNameKey] string] pathExtension];
	if ([[CBXADArchiveParserProxy archiveExtensionBlacklist] containsObject:extension])
		return nil;
	[self parseIfNeeded];
	@synchronized(baseArchive)
	{
		XADArchiveParser * subArchive = [XADArchiveParser
			archiveParserForEntryWithDictionary:entry archiveParser:archiveParser wantChecksum:YES];
		if (subArchive)
			return [CBXADArchiveParserProxy proxyWithArchiveParser:subArchive parent:self];
	}
	return nil;
}

- (NSData*)getDataForEntry:(NSDictionary*)entry
{
	[self parseIfNeeded];
	@synchronized(baseArchive)
	{
		CSHandle * dataHandle = [archiveParser handleForEntryWithDictionary:entry wantChecksum:YES];
		if (dataHandle)
			return [dataHandle remainingFileContents];
	}
	return nil;
}

- (BOOL)needsParsing
{
	return !parsed;
}

- (int)parseIfNeeded
{
	if ([self needsParsing])
	{
		return [self parse];
	}
	return XADNoError;
}

- (int)parse
{
	@synchronized(baseArchive)
	{
		XADError error = [archiveParser parseWithoutExceptions];
		parsed = (error == XADNoError);
		return error;
	}
	return nil;
}

- (int)parseWithDelegate:(id)delegate
{
	[archiveParser setDelegate:delegate];
	XADError error = [self parse];
	[archiveParser setDelegate:nil];
	return error;
}

+ (void)initialize
{
	if (archiveParserProxyCache == nil)
	{
		archiveParserProxyCache = [[NSCache alloc] init];
		archiveParserProxyCache.countLimit = 128;
		archiveParserProxyCache.name = @"Archive Parser Cache";
	}
	if (archiveExtensionBlacklist == nil)
	{
		archiveExtensionBlacklist = [[NSArray alloc] initWithObjects:@"db", nil];
	}
}

+ (NSArray*)archiveExtensionBlacklist
{
	return archiveExtensionBlacklist;
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

// Proxy
@implementation CBXADProxy

+ (BOOL)canLoadArchiveAtURL:(NSURL*)url
{
	@autoreleasepool
	{
		CBXADArchiveParserProxy * proxy = [CBXADArchiveParserProxy proxyWithArchiveURL:url];
		return proxy != nil;
	}
}

+ (BOOL)loadArchiveAtURL:(NSURL*)url
			   withBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback
{
	@autoreleasepool
	{
		CBXADArchiveParserProxy * proxy = [CBXADArchiveParserProxy proxyWithArchiveURL:url];
		if (proxy)
		{
			CBXADParserDelegate * delegate = [[CBXADParserDelegate alloc]
											  initWithBlock:fileCallback forURL:url];
			XADError error = [proxy parseWithDelegate:delegate];
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
		CBXADArchiveParserProxy * proxy = [CBXADArchiveParserProxy proxyWithArchiveFile:archiveFile];
		return proxy != nil;
	}
}

+ (BOOL)loadArchiveFromArchiveFile:(CBXADArchiveFileProxy*)archiveFile
						 withBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback
{
	@autoreleasepool
	{
		CBXADArchiveParserProxy * proxy = [CBXADArchiveParserProxy proxyWithArchiveFile:archiveFile];
		if (proxy)
		{
			CBXADParserDelegate * delegate = [[CBXADParserDelegate alloc]
					initWithBlock:fileCallback forURL:[archiveFile baseURL] entries:[archiveFile entries]];
			XADError error = [proxy parseWithDelegate:delegate];
			[delegate commit];
			[delegate release];
			return error == XADNoError;
		}
		return NO;
	}
}

@end
