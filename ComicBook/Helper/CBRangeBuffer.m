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
	}
	return self;
}

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

- (void)setStartIndex:(NSInteger)newStartIndex
{
	@synchronized (self)
	{
		[self shiftBy:(newStartIndex-startIndex) changedRange:NULL];
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

- (NSInteger)shiftUp
{
	CBRange range;
	[self shiftBy:1 changedRange:&range];
	return range.start;
}

- (NSInteger)shiftDown
{
	CBRange range;
	[self shiftBy:-1 changedRange:&range];
	return range.start;
}

- (void)shiftBy:(NSInteger)offset changedRange:(CBRange*)outRange
{
	@synchronized (self)
	{
		startIndex += offset;
		NSInteger bufferCount = [buffer count];
		bufferBaseIndex = (bufferBaseIndex + offset) % bufferCount;
		if (bufferBaseIndex < 0)
			bufferBaseIndex += bufferCount;
		if (outRange)
		{
			if (offset <= -bufferCount || offset >= bufferCount)
			{
				// Everything changed
				outRange->start = startIndex;
				outRange->end = startIndex + bufferCount;
			}
			else if (offset <= 0)
			{
				// Shifting down, only start changed
				outRange->start = startIndex;
				outRange->end = startIndex - offset;
			}
			else
			{
				// Shifting up, only end changed
				outRange->start = startIndex + bufferCount - offset;
				outRange->end = startIndex + bufferCount;
			}
		}
	}
}

- (void)shiftBy:(NSInteger)offset usingBlock:(void (^)(id obj, NSInteger idx))block
{
	@synchronized (self)
	{
		CBRange range;
		[self shiftBy:offset changedRange:&range];
		[self enumerateObjectsInRange:range usingBlock:block];
	}
}

- (void)shiftBy:(NSInteger)offset usingBlockAsync:(void (^)(id obj, NSInteger idx))block
{
	[self shiftBy:offset usingBlockAsync:block completion:NULL];
}

- (void)shiftBy:(NSInteger)offset usingBlockAsync:(void (^)(id obj, NSInteger idx))block
	 completion:(void (^)())completionBlock
{
	@synchronized (self)
	{
		CBRange range;
		[self shiftBy:offset changedRange:&range];
		[self enumerateObjectsInRange:range usingBlockAsync:block completion:completionBlock];
	}
}

- (void)shiftTo:(NSInteger)newStartIdx usingBlock:(void (^)(id obj, NSInteger idx))block
{
	[self shiftBy:(newStartIdx-startIndex) usingBlock:block];
}

- (void)shiftTo:(NSInteger)newStartIdx usingBlockAsync:(void (^)(id obj, NSInteger idx))block
{
	[self shiftBy:(newStartIdx-startIndex) usingBlockAsync:block];
}

- (void)shiftTo:(NSInteger)newStartIdx usingBlockAsync:(void (^)(id obj, NSInteger idx))block
	 completion:(void (^)())completionBlock
{
	[self shiftBy:(newStartIdx-startIndex) usingBlockAsync:block completion:completionBlock];
}

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSInteger idx))block
{
	@synchronized (self)
	{
		[self enumerateObjectsInRange:[self range] usingBlock:block];
	}
}

- (void)enumerateObjectsUsingBlockAsync:(void (^)(id obj, NSInteger idx))block
{
	[self enumerateObjectsUsingBlockAsync:block completion:NULL];
}

- (void)enumerateObjectsUsingBlockAsync:(void (^)(id obj, NSInteger idx))block
							 completion:(void (^)())completionBlock
{
	@synchronized (self)
	{
		[self enumerateObjectsInRange:[self range] usingBlockAsync:block completion:completionBlock];
	}
}

- (void)enumerateObjectsInRange:(CBRange)range usingBlock:(void (^)(id obj, NSInteger idx))block
{
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

- (void)enumerateObjectsInRange:(CBRange)range usingBlockAsync:(void (^)(id obj, NSInteger idx))block
{
	[self enumerateObjectsInRange:range usingBlockAsync:block completion:NULL];
}

- (void)enumerateObjectsInRange:(CBRange)range usingBlockAsync:(void (^)(id obj, NSInteger idx))block
					 completion:(void (^)())completionBlock
{
	@synchronized (self)
	{
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
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
		if (completionBlock)
		{
			dispatch_barrier_async(queue, completionBlock);
		}
	}
}

@end
