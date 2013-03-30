//
//  CBGeometryHelpers.c
//  ComicBook
//
//  Created by cbreak on 2013.03.30.
//  Copyright (c) 2013 the-color-black.net. All rights reserved.
//

#include "CBGeometryHelpers.h"

CGFloat CBPointPointDistance(CGPoint pointA, CGPoint pointB)
{
	CGPoint delta = { pointA.x - pointB.x, pointA.y - pointB.y };
	return sqrt(delta.x*delta.x + delta.y*delta.y);
}

CGFloat CBRectPointDistance(CGRect rect, CGPoint point)
{
	CGPoint p00 = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
	CGPoint p11 = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
	if (point.x < p00.x)
	{
		if (point.y < p00.y)
			return CBPointPointDistance(point, p00);
		else if (point.y > p11.y)
			return CBPointPointDistance(point, CGPointMake(p00.x, p11.y));
		else
			return p00.x - point.x;
	}
	if (point.x > p11.x)
	{
		if (point.y < p00.y)
			return CBPointPointDistance(point, CGPointMake(p11.x, p00.y));
		else if (point.y > p11.y)
			return CBPointPointDistance(point, p11);
		else
			return point.x - p11.x;
	}
	if (point.y < p00.y)
		return p00.y - point.y;
	else if (point.y > p11.y)
		return point.y - p11.y;
	return 0.0;
}
