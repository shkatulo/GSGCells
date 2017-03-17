//
//  GeometryHelpers.h
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/10/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#ifndef GeometryHelpers_h
#define GeometryHelpers_h

#import <UIKit/UIKit.h>
#import "UIBezierPath+Helpers.h"



CGPoint CGPointAdd(CGPoint point1, CGPoint point2);
CGPoint CGPointSubtract(CGPoint point1, CGPoint point2);
CGPoint CGPointMultiply(CGPoint point1, CGPoint point2);
CGPoint CGPointDivide(CGPoint point1, CGPoint point2);
CGPoint CGPointScale(CGPoint point, float scaleFactor);

float CGPointGetLength(CGPoint point);
float CGPointGetDistance(CGPoint point1, CGPoint point2);
CGPoint CGPointNormalize(CGPoint point);

BOOL CGPointIsAboveLine(CGPoint point, CGPoint linePointA, CGPoint linePointB);
BOOL CGPointIsOnTheRightSideOfLine(CGPoint point, CGPoint linePointA, CGPoint linePointB);



CGPoint *UIBezierGetLinearInterpolation(UIBezierPath *path, NSInteger segmentsPerElement, NSInteger *outPointsCount);
BOOL UIBezierPathGetFirstIntersection(UIBezierPath *path1, UIBezierPath *path2, NSInteger segmentsPerElement, CGPoint *outIntersectionPoint);
BOOL GetLinesIntersectionPoint(CGPoint pointA1, CGPoint pointA2, CGPoint pointB1, CGPoint pointB2, CGPoint *outIntersectionPoint);

#endif /* GeometryHelpers_h */
