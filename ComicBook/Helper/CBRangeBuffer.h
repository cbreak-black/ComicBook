//
//  CBRangeBuffer.h
//  ComicBook
//
//  Created by cbreak on 2012.12.31.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import <Foundation/NSArray.h>

/*!
 \brief A kind of ring buffer modeling an indexed range

 This class models a range buffer. Primary operations are inserting of objects (at the start, for
 creation), shifting up and shifting down.
 */
@interface CBRangeBuffer : NSObject
{
	NSMutableArray * buffer;
	NSInteger bufferBaseIndex;
	NSInteger startIndex;
}

- (id)init;

- (void)addObject:(id)anObject;
- (id)objectAtIndex:(NSInteger)index;

@property (assign) NSInteger startIndex;
@property (assign,readonly) NSInteger endIndex;

- (NSInteger)shiftUp;
- (NSInteger)shiftDown;
- (void)shiftBy:(NSInteger)offset changedRange:(NSInteger*)outRange;

- (void)shiftBy:(NSInteger)offset usingBlock:(void (^)(id obj, NSInteger idx))block;
- (void)shiftBy:(NSInteger)offset usingBlockAsync:(void (^)(id obj, NSInteger idx))block;

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSInteger idx))block;
- (void)enumerateObjectsUsingBlockAsync:(void (^)(id obj, NSInteger idx))block;

@end
