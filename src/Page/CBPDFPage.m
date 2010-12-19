//
//  CBPDFPage.m
//  ComicBook
//
//  Created by cbreak on 2010.12.19.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBPDFPage.h"

#import <Quartz/Quartz.h>

@implementation CBPDFPage

- (id)initWithPdfPage:(PDFPage*)pdfPage withPath:(NSString*)pdfPath
{
	self = [super init];
	if (self)
	{
		if (pdfPage)
		{
			page = [pdfPage retain];
			path = [pdfPath retain];
		}
		else
		{
			[self release];
			self = nil;
		}
	}
	return self;
}

- (void)dealloc
{
	[page release];
	[path release];
	[super dealloc];
}

// Loads the Image lazily (internal)
- (BOOL)loadImage
{
	NSImage * img = self.image;
	if (!img)
	{
		img = [[NSImage alloc] initWithData:[page dataRepresentation]];
		if (img && [img isValid])
		{
			NSImageRep * rep = [img bestRepresentationForRect:NSMakeRect(0, 0, 0, 0) context:nil hints:nil];
			if (rep)
			{
				NSSize s = [rep size];
				s.height *= 1680.0f/s.width;
				s.width *= 1680.0f/s.width;
//				[rep setSize:s];
				[rep setPixelsWide:s.width];
				[rep setPixelsHigh:s.height];
				[img setSize:s];
			}
			self.image = img;
			[img release];
		}
		else
		{
			// TODO: Set img to error image
			[img release];
			img = nil;
			NSLog(@"Error loading image from pdf document %@", [self path]);
		}
	}
	return img != nil;
}

@synthesize path;

// Creation

+ (NSArray*)pagesFromPdfFile:(NSURL*)pdfPath
{
	PDFDocument * doc = [[PDFDocument alloc] initWithURL:pdfPath];
	NSArray * pages = [CBPDFPage pagesFromPdfDocument:doc withPath:[pdfPath absoluteString]];
	[doc release];
	return pages;
}

+ (NSArray*)pagesFromPdfData:(NSData*)pdfData withPath:(NSString*)pdfPath
{
	PDFDocument * doc = [[PDFDocument alloc] initWithData:pdfData];
	NSArray * pages = [CBPDFPage pagesFromPdfDocument:doc withPath:pdfPath];
	[doc release];
	return pages;
}

+ (NSArray*)pagesFromPdfDocument:(PDFDocument*)document withPath:(NSString*)pdfPath
{
	if (document)
	{
		NSMutableArray * pages = [NSMutableArray arrayWithCapacity:1];
		for	(NSUInteger i = 0; i < [document pageCount]; i++)
		{
			PDFPage * pdfPage = [document pageAtIndex:i];
			CBPDFPage * page = [[CBPDFPage alloc] initWithPdfPage:pdfPage
														 withPath:[pdfPath stringByAppendingPathComponent:[pdfPage label]]];
			if (page)
				[pages addObject:page];
			[page release];
		}
		return pages;
	}
	else
	{
		return [NSArray array];
	}
}

+ (BOOL)validPdfAtURL:(NSURL*)url
{
	return [[url pathExtension] isEqualToString:@"pdf"];
}

@end
