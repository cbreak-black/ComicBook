//
//  CBRangeBuffer.m
//  ComicBook
//
//  Created by cbreak on 2012.12.31.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBRangeBuffer.h"

#import <dispatch/dispatch.h>

@implementation CBRangeBuffer

- (id)init
{
	if (self = [super init])
	{
		buffer = [[NSMutableArray alloc] init];
		queue = dispatch_queue_create("net.the-color-black.rangebuffer", DISPATCH_QUEUE_CONCURRENT);
	}
	return self;
}

- (void)dealloc
{
	dispatch_release(queue);
}

@synthesize exitBlock;
@synthesize enterBlock;
@synthesize postExit;
@synthesize postShift;
@synthesize postEnter;

- (NSUInteger)bufferIndexFromRangeIndex:(NSInteger)rangeIndex
{
	return (rangeIndex - startIndex + bufferBaseIndex) % [buffer count];
}

- (NSInteger)rangeIndexFromBufferIndex:(NSUInteger)bufferIndex
{
	NSInteger bufferCount = [buffer count];
	NSInteger rangeIndex = ((NSInteger)bufferIndex - bufferBaseIndex) % bufferCount;
	if (rangeIndex < 0) rangeIndex += bufferCount;
	rangeIndex += startIndex;
	return rangeIndex;
}

- (void)addObject:(id)anObject
{
	@synchronized (self)
	{
		if (bufferBaseIndex == 0)
		{
			[buffer addObject:anObject];
		}
		else
		{
			[buffer insertObject:anObject atIndex:bufferBaseIndex];
			++bufferBaseIndex;
		}
	}
}

- (id)objectAtIndex:(NSInteger)index
{
	@synchronized (self)
	{
		if (index < startIndex || [self endIndex] <= index)
			return nil;
		return [buffer objectAtIndex:[self bufferIndexFromRangeIndex:index]];
	}
}

- (void)replaceObjectAtIndex:(NSInteger)index withObject:(id)anObject
{
	@synchronized (self)
	{
		if (index < startIndex || [self endIndex] <= index)
			return;
		NSUInteger bufferIdx = [self bufferIndexFromRangeIndex:index];
		[buffer replaceObjectAtIndex:bufferIdx withObject:anObject];
	}
}

- (void)setStartIndex:(NSInteger)newStartIndex
{
	@synchronized (self)
	{
		[self shiftBy:(newStartIndex-startIndex)];
	}
}

- (NSInteger)startIndex
{
	@synchronized (self)
	{
		return startIndex;
	}
}

- (NSInteger)endIndex
{
	@synchronized (self)
	{
		return startIndex + [buffer count];
	}
}

- (CBRange)range
{
	@synchronized (self)
	{
		return CBRangeMake(startIndex, startIndex + [buffer count]);
	}
}

- (void)affectedRangeOfShiftBy:(NSInteger)offset exitRange:(CBRange*)exitRange enterRange:(CBRange*)enterRange;
{
	@synchronized (self)
	{
		NSInteger bufferCount = [buffer count];
		if (offset <= -bufferCount || offset >= bufferCount)
		{
			// Everything changed
			*exitRange = CBRangeMake(startIndex, startIndex + bufferCount);
			*enterRange = CBRangeMake(startIndex + offset, startIndex + bufferCount + offset);
		}
		else if (offset <= 0)
		{
			// Shifting down
			*exitRange = CBRangeMake(startIndex + bufferCount + offset, startIndex + bufferCount);
			*enterRange = CBRangeMake(startIndex + offset, startIndex);
		}
		else
		{
			// Shifting up
			*exitRange = CBRangeMake(startIndex, startIndex + offset);
			*enterRange = CBRangeMake(startIndex + bufferCount, startIndex + bufferCount + offset);
		}
	}
}

- (void)internalShiftBy:(NSInteger)offset
{
	@synchronized (self)
	{
		startIndex += offset;
		NSInteger bufferCount = [buffer count];
		bufferBaseIndex = (bufferBaseIndex + offset) % bufferCount;
		if (bufferBaseIndex < 0)
			bufferBaseIndex += bufferCount;
	}
}

- (void)shiftBy:(NSInteger)offset
{
	@synchronized (self)
	{
		CBRange exitRange, enterRange;
		[self affectedRangeOfShiftBy:offset exitRange:&exitRange enterRange:&enterRange];
		if (exitBlock)
			[self enumerateObjectsInRange:exitRange usingBlock:exitBlock];
		if (postExit)
			postExit();
		[self internalShiftBy:offset];
		if (postShift)
			postShift();
		if (enterBlock)
			[self enumerateObjectsInRange:enterRange usingBlock:enterBlock];
		if (postEnter)
			postEnter();
	}
}

- (void)asyncShiftBy:(NSInteger)offset
{
	[self asyncShiftBy:offset completion:NULL];
}

- (void)asyncShiftBy:(NSInteger)offset completion:(void (^)())completionBlock
{
	@synchronized (self)
	{
		CBRange exitRange, enterRange;
		[self affectedRangeOfShiftBy:offset exitRange:&exitRange enterRange:&enterRange];
		[self enumerateObjectsInRange:exitRange usingBlockAsync:exitBlock completion:^()
		{
			if (postExit)
				postExit();
			[self internalShiftBy:offset];
			if (postShift)
				postShift();
			[self enumerateObjectsInRange:enterRange usingBlockAsync:enterBlock completion:^()
			{
				if (postEnter)
					postEnter();
				if (completionBlock)
					completionBlock();
			}];
		 }];
	}
}

- (void)shiftTo:(NSInteger)newStartIdx
{
	[self shiftBy:(newStartIdx-startIndex)];
}

- (void)asyncShiftTo:(NSInteger)newStartIdx
{
	[self asyncShiftBy:(newStartIdx-startIndex)];
}

- (void)asyncShiftTo:(NSInteger)newStartIdx completion:(CBRangeVoidBlock)completionBlock
{
	[self asyncShiftBy:(newStartIdx-startIndex) completion:completionBlock];
}

- (void)enumerateObjectsUsingBlock:(CBRangeObjectBlock)block
{
	@synchronized (self)
	{
		[self enumerateObjectsInRange:[self range] usingBlock:block];
	}
}

- (void)enumerateObjectsUsingBlockAsync:(CBRangeObjectBlock)block
{
	[self enumerateObjectsUsingBlockAsync:block completion:NULL];
}

- (void)enumerateObjectsUsingBlockAsync:(CBRangeObjectBlock)block
							 completion:(CBRangeVoidBlock)completionBlock
{
	@synchronized (self)
	{
		[self enumerateObjectsInRange:[self range] usingBlockAsync:block completion:completionBlock];
	}
}

- (void)enumerateObjectsInRange:(CBRange)range usingBlock:(CBRangeObjectBlock)block
{
	if (!block)
		return;
	@synchronized (self)
	{
		if (range.start < startIndex) range.start = startIndex;
		if (range.end > [self endIndex]) range.end = [self endIndex];
		for (NSInteger idx = range.start; idx < range.end; ++idx)
		{
			block([self objectAtIndex:idx], idx);
		}
	}
}

- (void)enumerateObjectsInRange:(CBRange)range usingBlockAsync:(CBRangeObjectBlock)block
{
	[self enumerateObjectsInRange:range usingBlockAsync:block completion:NULL];
}

- (void)enumerateObjectsInRange:(CBRange)range usingBlockAsync:(CBRangeObjectBlock)block
					 completion:(CBRangeVoidBlock)completionBlock
{
	@synchronized (self)
	{
		if (block)
		{
			if (range.start < startIndex) range.start = startIndex;
			if (range.end > [self endIndex]) range.end = [self endIndex];
			for (NSInteger idx = range.start; idx < range.end; ++idx)
			{
				id obj = [self objectAtIndex:idx];
				dispatch_async(queue, ^()
				{
					block(obj, idx);
				});
			}
		}
		if (completionBlock)
		{
			dispatch_barrier_async(queue, completionBlock);
		}
	}
}

@end
