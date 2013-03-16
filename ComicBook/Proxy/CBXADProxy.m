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
	}
	return self;
}

- (void)dealloc
{
	[entry release];
	[archive release];
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
		@synchronized (archive)
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

@end

// Delegate for parsing
@interface CBXADArchiveParserDelegate : NSObject
{
	void (^fileCallback)(CBXADArchiveFileProxy*);
}

- (id)initWithBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback;

- (void)archiveParser:(XADArchiveParser *)parser foundEntryWithDictionary:(NSDictionary *)dict;
- (BOOL)archiveParsingShouldStop:(XADArchiveParser *)parser;
- (void)archiveParserNeedsPassword:(XADArchiveParser *)parser;
- (void)archiveParser:(XADArchiveParser *)parser findsFileInterestingForReason:(NSString *)reason;

@end

@implementation CBXADArchiveParserDelegate

- (id)initWithBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback_
{
	if (self = [super init])
	{
		fileCallback = fileCallback_;
	}
	return self;
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
		CBXADArchiveFileProxy * archiveFile = [[CBXADArchiveFileProxy alloc] initWithEntry:dict inArchive:parser];
		fileCallback(archiveFile);
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
		return [self loadArchiveFromParser:parser withBlock:fileCallback];
	}
	return NO;
}

+ (BOOL)loadArchiveFromParser:(XADArchiveParser*)parser
					withBlock:(void (^)(CBXADArchiveFileProxy*))fileCallback
{
	@synchronized (parser)
	{
		CBXADArchiveParserDelegate * delegate = [[CBXADArchiveParserDelegate alloc] initWithBlock:fileCallback];
		[parser setDelegate:delegate];
		XADError error = [parser parseWithoutExceptions];
		[delegate release];
		return error == XADNoError;
	}
}

@end
