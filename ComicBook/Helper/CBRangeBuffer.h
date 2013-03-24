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

typedef void (^CBRangeObjectBlock)(id obj, NSInteger idx);
typedef void (^CBRangeVoidBlock)();

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
	// Blocks
	CBRangeObjectBlock exitBlock;
	CBRangeObjectBlock enterBlock;
	CBRangeVoidBlock postExit;
	CBRangeVoidBlock postShift;
	CBRangeVoidBlock postEnter;
}

- (id)init;

@property (nonatomic,copy) CBRangeObjectBlock exitBlock;
@property (nonatomic,copy) CBRangeObjectBlock enterBlock;
@property (nonatomic,copy) CBRangeVoidBlock postExit;
@property (nonatomic,copy) CBRangeVoidBlock postShift;
@property (nonatomic,copy) CBRangeVoidBlock postEnter;

- (void)addObject:(id)anObject;
- (id)objectAtIndex:(NSInteger)index;
- (void)replaceObjectAtIndex:(NSInteger)index withObject:(id)anObject;

@property (assign) NSInteger startIndex;
@property (assign,readonly) NSInteger endIndex;
@property (assign,readonly) CBRange range;

- (void)affectedRangeOfShiftBy:(NSInteger)offset exitRange:(CBRange*)exitRange enterRange:(CBRange*)enterRange;

- (void)shiftBy:(NSInteger)offset;
- (void)asyncShiftBy:(NSInteger)offset;
- (void)asyncShiftBy:(NSInteger)offset completion:(CBRangeVoidBlock)completionBlock;

- (void)shiftTo:(NSInteger)newStartIdx;
- (void)asyncShiftTo:(NSInteger)newStartIdx;
- (void)asyncShiftTo:(NSInteger)newStartIdx completion:(CBRangeVoidBlock)completionBlock;

- (void)enumerateObjectsUsingBlock:(CBRangeObjectBlock)block;
- (void)enumerateObjectsUsingBlockAsync:(CBRangeObjectBlock)block;
- (void)enumerateObjectsUsingBlockAsync:(CBRangeObjectBlock)block
							 completion:(CBRangeVoidBlock)completionBlock;

- (void)enumerateObjectsInRange:(CBRange)range usingBlock:(CBRangeObjectBlock)block;
- (void)enumerateObjectsInRange:(CBRange)range usingBlockAsync:(CBRangeObjectBlock)block;
- (void)enumerateObjectsInRange:(CBRange)range usingBlockAsync:(CBRangeObjectBlock)block
					 completion:(CBRangeVoidBlock)completionBlock;

@end
