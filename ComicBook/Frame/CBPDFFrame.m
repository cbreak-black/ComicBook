//
//  CBPDFFrame.m
//  ComicBook
//
//  Created by cbreak on 2012.12.22.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBPDFFrame.h"

#import <Quartz/Quartz.h>

@interface CBPDFFrameLoader : NSObject<CBFrameLoader>
@end

@implementation CBPDFFrameLoader

- (BOOL)canLoadFramesFromURL:(NSURL*)url
{
	return [[url pathExtension] isEqualToString:@"pdf"];
}

- (NSArray*)loadFramesFromURL:(NSURL*)url
{
	if ([self canLoadFramesFromURL:url])
		return [self pagesFromPdfFile:url];
	else
		return nil;
}

- (BOOL)canLoadFramesFromData:(NSData*)data withPath:(NSString*)path
{
	NSString * fileExtension = [path pathExtension];
	return [fileExtension isEqualToString:@"pdf"];
}

- (NSArray*)loadFramesFromData:(NSData*)data withPath:(NSString*)path
{
	if ([self canLoadFramesFromData:data withPath:path])
		return [self pagesFromPdfData:data withPath:path];
	else
		return nil;
}

- (NSArray*)pagesFromPdfFile:(NSURL*)pdfPath
{
	PDFDocument * doc = [[PDFDocument alloc] initWithURL:pdfPath];
	return [self pagesFromPdfDocument:doc withPath:[pdfPath absoluteString]];
}

- (NSArray*)pagesFromPdfData:(NSData*)pdfData withPath:(NSString*)pdfPath
{
	PDFDocument * doc = [[PDFDocument alloc] initWithData:pdfData];
	return [self pagesFromPdfDocument:doc withPath:pdfPath];
}

- (NSArray*)pagesFromPdfDocument:(PDFDocument*)document withPath:(NSString*)pdfPath
{
	if (document)
	{
		NSMutableArray * pages = [NSMutableArray arrayWithCapacity:1];
		for	(NSUInteger i = 0; i < [document pageCount]; i++)
		{
			PDFPage * pdfPage = [document pageAtIndex:i];
			NSString * name = [pdfPath stringByAppendingPathComponent:[pdfPage label]];
			CBPDFFrame * page = [[CBPDFFrame alloc] initWithPdfPage:pdfPage withPath:name];
			if (page)
				[pages addObject:page];
		}
		return pages;
	}
	else
	{
		return nil;
	}
}

@end

@implementation CBPDFFrame

- (id)initWithPdfPage:(PDFPage*)pdfPage withPath:(NSString*)pdfPath
{
	if (self = [super init])
	{
		if (pdfPage)
		{
			page = pdfPage;
			path = pdfPath;
		}
		else
		{
			self = nil;
		}
	}
	return self;
}

- (NSImage*)image
{
	NSImage * image = [[NSImage alloc] initWithData:[page dataRepresentation]];
	if (image && [image isValid])
	{
		NSImageRep * rep = [image bestRepresentationForRect:NSMakeRect(0, 0, 0, 0) context:nil hints:nil];
		if (rep)
		{
			NSSize s = [rep size];
			s.height *= 1680.0f/s.width;
			s.width *= 1680.0f/s.width;
			//				[rep setSize:s];
			[rep setPixelsWide:s.width];
			[rep setPixelsHigh:s.height];
			[image setSize:s];
		}
		return image;
	}
	else
	{
		NSLog(@"Error loading image from pdf file %@", [self path]);
		return [super image];
	}
}

@synthesize path;

+ (id<CBFrameLoader>)loader
{
	return [[CBPDFFrameLoader alloc] init];
}

@end
