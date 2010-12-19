//
//  CBPDFPage.h
//  ComicBook
//
//  Created by cbreak on 2010.12.19.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CBPage.h"

@class PDFDocument;
@class PDFPage;

// A page backed from a PDF File

@interface CBPDFPage : CBPage
{
	PDFPage * page;
	NSString * path;
}

- (id)initWithPdfPage:(PDFPage*)pdfPage withPath:(NSString*)pdfPath;

// Creation
+ (NSArray*)pagesFromPdfFile:(NSURL*)pdfPath;
+ (NSArray*)pagesFromPdfData:(NSData*)pdfData withPath:(NSString*)pdfPath;
+ (NSArray*)pagesFromPdfDocument:(PDFDocument*)document withPath:(NSString*)pdfPath;
+ (BOOL)validPdfAtURL:(NSURL*)url;
@end
