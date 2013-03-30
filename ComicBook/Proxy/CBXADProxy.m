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

- (id)initWithEntry:(NSDictionary*)entry_ inArchive:(XADArchiveParser*)archive_
{
	if (self = [super init])
	{
		entry = [entry_ retain];
		archive = [archive_ retain];
		master = [archive_ retain];
	}
	return self;
}

- (id)initWithEntry:(NSDictionary*)entry_ inArchive:(XADArchiveParser*)archive_
								  withMasterArchive:(XADArchiveParser*)master_
{
	if (self = [super init])
	{
		entry = [entry_ retain];
		archive = [archive_ retain];
		master = [master_ retain];
	}
	return self;
}

- (void)dealloc
{
	[entry release];
	[archive release];
	[master release];
	[super dealloc];
}

- (NSString*)path
{
	NSString * filePath = [[entry objectForKey:XADFileNameKey] string];
	return [[archive filename] stringByAppendingPathComponent:filePath];
}

- (NSData*)data
{
	@try
	{
		// Lock on master, so no archive, not even other sub archives, are used concurrently
		@synchronized (master)
		{
			CSHandle * archiveDataHandle = [archive handleForEntryWithDictionary:entry wantChecksum:YES];
			return [archiveDataHandle remainingFileContents];
		}
	}
	@catch (NSException * e)
	{
		NSLog(@"Exception %@ reading archive at path %@", e, [self path]);
	}
	return nil;
}

@synthesize entry;
@synthesize archive;
@synthesize master;

@end

// Delegate for parsing
@interface CBXADArchiveParserDelegate : NSObject
{
	NSMutableArray * files;
	void (^fileCallback)(CBXADArchiveFileProxy*); // Non-owning
	XADArchiveParser * master; // Non-owning
}

- (id)initWithBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback withMasterArchive:(XADArchiveParser*)master;

- (void)commit;

- (void)archiveParser:(XADArchiveParser *)parser foundEntryWithDictionary:(NSDictionary *)dict;
- (BOOL)archiveParsingShouldStop:(XADArchiveParser *)parser;
- (void)archiveParserNeedsPassword:(XADArchiveParser *)parser;
- (void)archiveParser:(XADArchiveParser *)parser findsFileInterestingForReason:(NSString *)reason;

@end

@implementation CBXADArchiveParserDelegate

- (id)initWithBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback_ withMasterArchive:(XADArchiveParser*)master_
{
	if (self = [super init])
	{
		files = [[NSMutableArray alloc] initWithCapacity:32];
		fileCallback = fileCallback_;
		master = master_;
	}
	return self;
}

- (void)dealloc
{
	[files release];
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
		CBXADArchiveFileProxy * archiveFile = [[CBXADArchiveFileProxy alloc]
				initWithEntry:dict inArchive:parser withMasterArchive:master];
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
	XADError error = XADNoError;
	XADArchiveParser * parser = [XADArchiveParser archiveParserForPath:[url path] error:&error];
	return (parser && error == XADNoError);
}

+ (BOOL)loadArchiveAtURL:(NSURL*)url
			   withBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback
{
	XADError error = XADNoError;
	XADArchiveParser * parser = [XADArchiveParser archiveParserForPath:[url path] error:&error];
	if (parser && error == XADNoError)
		return [self loadArchiveFromParser:parser withBlock:fileCallback];
	return NO;
}

+ (BOOL)canLoadArchiveFromArchiveFile:(CBXADArchiveFileProxy*)archiveFile
{
	XADError error = XADNoError;
	XADArchiveParser * parser = [XADArchiveParser archiveParserForEntryWithDictionary:[archiveFile entry]
		archiveParser:[archiveFile archive] wantChecksum:NO error:&error];
	return (parser && error == XADNoError);
}

+ (BOOL)loadArchiveFromArchiveFile:(CBXADArchiveFileProxy*)archiveFile
						 withBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback
{
	XADError error = XADNoError;
	XADArchiveParser * parser = [XADArchiveParser archiveParserForEntryWithDictionary:[archiveFile entry]
		archiveParser:[archiveFile archive] wantChecksum:NO error:&error];
	if (parser && error == XADNoError)
	{
		if ([parser filename] == nil)
			[parser setFilename:[archiveFile path]];
		return [self loadArchiveFromParser:parser master:[archiveFile master] withBlock:fileCallback];
	}
	return NO;
}

+ (BOOL)loadArchiveFromParser:(XADArchiveParser*)parser
					withBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback
{
	return [self loadArchiveFromParser:parser master:parser withBlock:fileCallback];
}

+ (BOOL)loadArchiveFromParser:(XADArchiveParser*)parser master:(XADArchiveParser*)master
					withBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback
{
	@synchronized (parser)
	{
		CBXADArchiveParserDelegate * delegate = [[CBXADArchiveParserDelegate alloc]
			initWithBlock:fileCallback withMasterArchive:master];
		[parser setDelegate:delegate];
		XADError error = [parser parseWithoutExceptions];
		[delegate commit];
		[delegate release];
		return error == XADNoError;
	}
}

@end
