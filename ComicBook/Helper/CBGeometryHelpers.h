//
//  CBGeometryHelpers.h
//  ComicBook
//
//  Created by cbreak on 2013.03.30.
//  Copyright (c) 2013 the-color-black.net. All rights reserved.
//

#ifndef CBGEOMETRYHELPERS_H
#define CBGEOMETRYHELPERS_H

// For <CoreGraphics/CGGeometry.h>
#include <ApplicationServices/ApplicationServices.h>

extern CGFloat CBPointPointDistance(CGPoint pointA, CGPoint pointB);
extern CGFloat CBRectPointDistance(CGRect rect, CGPoint point);

#endif
