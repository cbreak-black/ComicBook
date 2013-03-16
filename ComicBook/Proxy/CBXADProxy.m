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
	XADError error = XADNoError;
	CSHandle * archiveDataHandle = [archive handleForEntryWithDictionary:entry
															wantChecksum:YES error:&error];
	if (error == XADNoError)
	{
		return [archiveDataHandle remainingFileContents];
	}
	NSLog(@"Error %@ reading archive at path %@", [XADException describeXADError:error], [self path]);
	return nil;
}

@synthesize entry;
@synthesize archive;

@end

// Delegate for parsing
@interface CBXADArchiveParserDelegate : NSObject
{
	NSMutableArray * archiveFiles;
}

- (id)init;
- (void)dealloc;

- (NSArray*)archiveFiles;

- (void)archiveParser:(XADArchiveParser *)parser foundEntryWithDictionary:(NSDictionary *)dict;
- (BOOL)archiveParsingShouldStop:(XADArchiveParser *)parser;
- (void)archiveParserNeedsPassword:(XADArchiveParser *)parser;
- (void)archiveParser:(XADArchiveParser *)parser findsFileInterestingForReason:(NSString *)reason;

@end

@implementation CBXADArchiveParserDelegate

- (id)init
{
	if (self = [super init])
	{
		archiveFiles = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[archiveFiles release];
	[super dealloc];
}

- (NSArray*)archiveFiles
{
	return archiveFiles;
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
		[archiveFiles addObject:archiveFile];
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

+ (NSArray*)loadArchiveAtURL:(NSURL*)url error:(NSError **)outError
{
	XADError error = XADNoError;
	XADArchiveParser * parser = [XADArchiveParser archiveParserForPath:[url path] error:&error];
	if (parser && error == XADNoError)
		return [self loadArchiveFromParser:parser error:error];
	return nil;
}

+ (BOOL)canLoadArchiveFromArchiveFile:(CBXADArchiveFileProxy*)archiveFile
{
	XADError error = XADNoError;
	XADArchiveParser * parser = [XADArchiveParser archiveParserForEntryWithDictionary:[archiveFile entry]
		archiveParser:[archiveFile archive] wantChecksum:NO error:&error];
	return (parser && error == XADNoError);
}

+ (NSArray*)loadArchiveFromArchiveFile:(CBXADArchiveFileProxy*)archiveFile error:(NSError **)outError
{
	XADError error = XADNoError;
	XADArchiveParser * parser = [XADArchiveParser archiveParserForEntryWithDictionary:[archiveFile entry]
		archiveParser:[archiveFile archive] wantChecksum:NO error:&error];
	if (parser && error == XADNoError)
	{
		if ([parser filename] == nil)
			[parser setFilename:[archiveFile path]];
		return [self loadArchiveFromParser:parser error:error];
	}
	return nil;
}

+ (NSArray*)loadArchiveFromParser:(XADArchiveParser*)parser error:(NSError **)error
{
	CBXADArchiveParserDelegate * delegate = [[CBXADArchiveParserDelegate alloc] init];
	[parser setDelegate:delegate];
	[parser parse];
	NSArray * files = [[[delegate archiveFiles] retain] autorelease];
	[delegate release];
	return files;
}

@end
