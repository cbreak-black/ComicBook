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

- (NSInteger)shiftUp
{
	NSInteger range[2];
	[self shiftBy:1 changedRange:range];
	return range[0];
}

- (NSInteger)shiftDown
{
	NSInteger range[2];
	[self shiftBy:-1 changedRange:range];
	return range[0];
}

- (void)shiftBy:(NSInteger)offset changedRange:(NSInteger*)outRange
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
				outRange[0] = startIndex;
				outRange[1] = startIndex + bufferCount;
			}
			else if (offset <= 0)
			{
				// Shifting down, only start changed
				outRange[0] = startIndex;
				outRange[1] = startIndex - offset;
			}
			else
			{
				// Shifting up, only end changed
				outRange[0] = startIndex + bufferCount - offset;
				outRange[1] = startIndex + bufferCount;
			}
		}
	}
}

- (void)shiftBy:(NSInteger)offset usingBlock:(void (^)(id obj, NSInteger idx))block
{
	@synchronized (self)
	{
		NSInteger range[2];
		[self shiftBy:offset changedRange:range];
		for (NSInteger idx = range[0]; idx < range[1]; ++idx)
		{
			block([self objectAtIndex:idx], idx);
		}
	}
}

- (void)shiftBy:(NSInteger)offset usingBlockAsync:(void (^)(id obj, NSInteger idx))block
{
	@synchronized (self)
	{
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		NSInteger range[2];
		[self shiftBy:offset changedRange:range];
		for (NSInteger idx = range[0]; idx < range[1]; ++idx)
		{
			id obj = [self objectAtIndex:idx];
			dispatch_async(queue, ^()
			{
				block(obj, idx);
			});
		}
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

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSInteger idx))block
{
	@synchronized (self)
	{
		NSUInteger bufferIdx = 0;
		for (id obj in buffer)
		{
			NSInteger rangeIdx = [self rangeIndexFromBufferIndex:bufferIdx];
			++bufferIdx;
			block(obj, rangeIdx);
		}
	}
}

- (void)enumerateObjectsUsingBlockAsync:(void (^)(id obj, NSInteger idx))block
{
	@synchronized (self)
	{
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		NSUInteger bufferIdx = 0;
		for (id obj in buffer)
		{
			NSInteger rangeIdx = [self rangeIndexFromBufferIndex:bufferIdx];
			++bufferIdx;
			dispatch_async(queue, ^()
			{
				block(obj, rangeIdx);
			});
		}
	}
}

@end
