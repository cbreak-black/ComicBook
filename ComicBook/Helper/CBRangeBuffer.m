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
		NSInteger bufferIndex = (index - startIndex + bufferBaseIndex) % [buffer count];
		return [buffer objectAtIndex:bufferIndex];
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
		NSUInteger bufferCount = [buffer count];
		bufferBaseIndex = (bufferBaseIndex + offset) % bufferCount;
		if (bufferBaseIndex < 0)
			bufferBaseIndex += bufferCount;
		if (outRange)
		{
			if (offset <= -bufferCount || offset >= bufferCount)
			{
				outRange[0] = startIndex;
				outRange[1] = startIndex + bufferCount;
			}
			else if (offset <= 0)
			{
				outRange[0] = startIndex;
				outRange[1] = startIndex - offset;
			}
			else
			{
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

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSInteger idx))block
{
	@synchronized (self)
	{
		NSInteger idx = startIndex;
		for (id obj in buffer)
		{
			block(obj, idx);
			++idx;
		}
	}
}

- (void)enumerateObjectsUsingBlockAsync:(void (^)(id obj, NSInteger idx))block
{
	@synchronized (self)
	{
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		NSInteger idx = startIndex;
		for (id obj in buffer)
		{
			dispatch_async(queue, ^()
			{
				block(obj, idx);
			});
			++idx;
		}
	}
}

@end
