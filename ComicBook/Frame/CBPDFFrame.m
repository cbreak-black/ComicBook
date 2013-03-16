//
//  CBPDFFrame.m
//  ComicBook
//
//  Created by cbreak on 2012.12.22.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBPDFFrame.h"

#import <Quartz/Quartz.h>

@implementation CBPDFFrameLoader

- (BOOL)canLoadFramesFromURL:(NSURL*)url
{
	return [[url pathExtension] isEqualToString:@"pdf"];
}

- (BOOL)loadFramesFromURL:(NSURL*)url withBlock:(void (^)(CBFrame*))frameCallback
{
	PDFDocument * doc = [[PDFDocument alloc] initWithURL:url];
	return [self pagesFromPdfDocument:doc withPath:[url absoluteString] withBlock:frameCallback];
}

- (BOOL)canLoadFramesFromDataSource:(id<CBFrameDataSource>)dataSource;
{
	NSString * fileExtension = [[dataSource framePath] pathExtension];
	return [fileExtension isEqualToString:@"pdf"];
}

- (BOOL)loadFramesFromDataSource:(id<CBFrameDataSource>)dataSource withBlock:(void (^)(CBFrame*))frameCallback
{
	PDFDocument * doc = [[PDFDocument alloc] initWithData:[dataSource frameData]];
	return [self pagesFromPdfDocument:doc withPath:[dataSource framePath] withBlock:frameCallback];
}

- (BOOL)pagesFromPdfDocument:(PDFDocument*)document withPath:(NSString*)pdfPath
				   withBlock:(void (^)(CBFrame*))frameCallback
{
	if (document)
	{
		for	(NSUInteger i = 0; i < [document pageCount]; i++)
		{
			PDFPage * pdfPage = [document pageAtIndex:i];
			NSString * name = [pdfPath stringByAppendingPathComponent:[pdfPage label]];
			CBPDFFrame * page = [[CBPDFFrame alloc] initWithPdfPage:pdfPage withPath:name];
			if (page)
				frameCallback(page);
		}
		return YES;
	}
	return NO;
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

@end
