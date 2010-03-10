//
//  CBPageOperation.h
//  ComicBook
//
//  Created by cbreak on 10.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CBPage;

@interface CBPageOperation : NSOperation
{
	CBPage * page;
}

@property (retain) CBPage * page;

@end

// Preloads a page calling beginContentAccess on it
@interface CBPreloadOperation : CBPageOperation
{
}

- (void)main;

@end

// Unloads the given page calling endContentAccess and discardContentIfPossible
@interface CBUnloadOperation : CBPageOperation
{
}

- (void)main;

@end
