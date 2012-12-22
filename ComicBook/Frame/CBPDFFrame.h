//
//  CBPDFFrame.h
//  ComicBook
//
//  Created by cbreak on 2012.12.22.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBFrame.h"

@class PDFDocument;
@class PDFPage;

@interface CBPDFFrame : CBFrame
{
	PDFPage * page;
	NSString * path;
}

- (id)initWithPdfPage:(PDFPage*)pdfPage withPath:(NSString*)pdfPath;

@property (retain, readonly) NSString * path;
@property (retain, readonly) NSImage * image;
+ (id<CBFrameLoader>)loader;
@end
