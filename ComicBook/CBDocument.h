//
//  CBDocument.h
//  ComicBook
//
//  Created by cbreak on 2012.12.15.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CBComicModel;
@class CBComicWindowController;

@interface CBDocument : NSDocument
{
	CBComicModel * comic;
	CBComicWindowController * comicWindow;
}

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName;

@end
