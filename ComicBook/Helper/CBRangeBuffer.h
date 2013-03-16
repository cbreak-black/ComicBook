//
//  CBRangeBuffer.h
//  ComicBook
//
//  Created by cbreak on 2012.12.31.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import <Foundation/NSArray.h>

/*!
 \brief Standard half-open signed range [start, end[
 */
typedef struct
{
	NSInteger start;
	NSInteger end;
} CBRange;

NS_INLINE CBRange CBRangeMake(NSInteger s, NSInteger e)
{
	CBRange range = { s, e };
	return range;
}

/*!
 \brief A kind of ring buffer modeling an indexed range

 This class models a range buffer. Primary operations are inserting of objects (at the start, for
 creation), shifting up and shifting down.
 */
@interface CBRangeBuffer : NSObject
{
	NSMutableArray * buffer;
	NSInteger bufferBaseIndex; ///< First element in the buffer is at this buffer index
	NSInteger startIndex;      ///< First element in the buffer has this range index
}

- (id)init;

- (void)addObject:(id)anObject;
- (id)objectAtIndex:(NSInteger)index;

@property (assign) NSInteger startIndex;
@property (assign,readonly) NSInteger endIndex;
@property (assign,readonly) CBRange range;

- (NSInteger)shiftUp;
- (NSInteger)shiftDown;
- (void)shiftBy:(NSInteger)offset changedRange:(CBRange*)outRange;

- (void)shiftBy:(NSInteger)offset usingBlock:(void (^)(id obj, NSInteger idx))block;
- (void)shiftBy:(NSInteger)offset usingBlockAsync:(void (^)(id obj, NSInteger idx))block;
- (void)shiftBy:(NSInteger)offset usingBlockAsync:(void (^)(id obj, NSInteger idx))block
	 completion:(void (^)())completionBlock;

- (void)shiftTo:(NSInteger)newStartIdx usingBlock:(void (^)(id obj, NSInteger idx))block;
- (void)shiftTo:(NSInteger)newStartIdx usingBlockAsync:(void (^)(id obj, NSInteger idx))block;
- (void)shiftTo:(NSInteger)newStartIdx usingBlockAsync:(void (^)(id obj, NSInteger idx))block
	 completion:(void (^)())completionBlock;

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSInteger idx))block;
- (void)enumerateObjectsUsingBlockAsync:(void (^)(id obj, NSInteger idx))block;
- (void)enumerateObjectsUsingBlockAsync:(void (^)(id obj, NSInteger idx))block
							 completion:(void (^)())completionBlock;

- (void)enumerateObjectsInRange:(CBRange)range usingBlock:(void (^)(id obj, NSInteger idx))block;
- (void)enumerateObjectsInRange:(CBRange)range usingBlockAsync:(void (^)(id obj, NSInteger idx))block;
- (void)enumerateObjectsInRange:(CBRange)range usingBlockAsync:(void (^)(id obj, NSInteger idx))block
					 completion:(void (^)())completionBlock;

@end
