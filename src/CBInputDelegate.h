//
//  CBInputDelegate.h
//  ComicBook
//
//  Created by cbreak on 10.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CBPage;

@protocol CBInputDelegate

// For Input
- (void)advancePage:(NSInteger)offset;
- (void)setCurrentPage:(NSUInteger)number;

// For Output
- (CBPage *)pageAtIndex:(NSUInteger)number;
- (NSUInteger)currentPage;

@end
