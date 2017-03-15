//
//  GeometryHelpers.m
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/10/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import "GeometryHelpers.h"
#import <PerformanceBezier/PerformanceBezier.h>



CGPoint CGPointAdd(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}



CGPoint CGPointSubtract(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x - point2.x, point1.y - point2.y);
}



CGPoint CGPointMultiply(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x * point2.x, point1.y * point2.y);
}



CGPoint CGPointDivide(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x / point2.x, point1.y / point2.y);
}



CGPoint CGPointScale(CGPoint point, float scaleFactor) {
    return CGPointMake(point.x * scaleFactor, point.y * scaleFactor);
}



float CGPointGetLength(CGPoint point) {
    return sqrtf(point.x * point.x + point.y * point.y);
}



float CGPointGetDistance(CGPoint point1, CGPoint point2) {
    float dx = point2.x - point1.x;
    float dy = point2.y - point1.y;
    return sqrtf(dx * dx + dy * dy);
}



CGPoint CGPointNormalize(CGPoint point) {
    float len = CGPointGetLength(point);
    return CGPointMake(point.x / len, point.y / len);
}



CGPoint *UIBezierGetLinearInterpolation(UIBezierPath *path, NSInteger segmentsPerElement, NSInteger *outPointsCount) {
    NSInteger elementsCount = path.elementCount;
    NSInteger pointsCount = (elementsCount - 1) * segmentsPerElement + 1;
    CGPoint *points = calloc(pointsCount, sizeof(CGPoint));
    NSInteger pointIndex = 0;
    
    CGPoint prevPoint = CGPointZero;
    for (int i = 0; i < elementsCount; ++i) {
        CGPoint elementPoints[3];
        CGPathElement element = [path elementAtIndex:i associatedPoints:elementPoints];
        
        // Initial move to point element
        if (element.type == kCGPathElementMoveToPoint) {
            prevPoint = elementPoints[0];
        }
        // Bezier path element
        else if (element.type == kCGPathElementAddCurveToPoint) {
            CGPoint bezier[4] = { prevPoint, elementPoints[0], elementPoints[1], elementPoints[2] };
            prevPoint = elementPoints[2];
            
            // Add points of element
            for (int segment = 0; segment < segmentsPerElement; ++segment) {
                float t = (1.0f / segmentsPerElement) * segment;
                CGPoint point = [UIBezierPath pointAtT:t forBezier:bezier];
                
                points[pointIndex++] = point;
//                NSLog(@"Point: (%f, %f)", point.x, point.y);
            }
            
            // Add end point of the last path element
            if (i == elementsCount - 1) {
                CGPoint point = [UIBezierPath pointAtT:1 forBezier:bezier];
                points[pointIndex++] = point;
            }
        }
//        NSLog(@"");
    }
    
    if (outPointsCount) {
        *outPointsCount = pointsCount;
    }
    
    return points;
}



BOOL UIBezierPathGetFirstIntersection(UIBezierPath *path1, UIBezierPath *path2, NSInteger segmentsPerElement, CGPoint *outIntersectionPoint) {
    NSInteger path1PointsCount, path2PointsCount;
    CGPoint *path1Points = UIBezierGetLinearInterpolation(path1, segmentsPerElement, &path1PointsCount);
    CGPoint *path2Points = UIBezierGetLinearInterpolation(path2, segmentsPerElement, &path2PointsCount);
    
    BOOL intersects = NO;
    for (NSInteger p1Index = 0; p1Index < path1PointsCount - 1; ++p1Index) {
        for (NSInteger p2Index = 0; p2Index < path2PointsCount - 1; ++p2Index) {
            intersects = GetLinesIntersectionPoint(path1Points[p1Index], path1Points[p1Index + 1], path2Points[p2Index], path2Points[p2Index + 1], outIntersectionPoint);
            
            if (intersects)
                break;
        }
        
        if (intersects)
            break;
    }
    
    free(path1Points);
    free(path2Points);
    
    return intersects;
}



BOOL GetLinesIntersectionPoint(CGPoint pointA1, CGPoint pointA2, CGPoint pointB1, CGPoint pointB2, CGPoint *outIntersectionPoint) {
    CGFloat d = (pointA2.x - pointA1.x) * (pointB2.y - pointB1.y) - (pointA2.y - pointA1.y) * (pointB2.x - pointB1.x);
    
    if (d == 0)
        return NO; // parallel lines
    
    CGFloat u = ((pointB1.x - pointA1.x) * (pointB2.y - pointB1.y) - (pointB1.y - pointA1.y) * (pointB2.x - pointB1.x)) / d;
    CGFloat v = ((pointB1.x - pointA1.x) * (pointA2.y - pointA1.y) - (pointB1.y - pointA1.y) * (pointA2.x - pointA1.x)) / d;
    
    if (u < 0.0 || u > 1.0)
        return NO; // intersection point not between pointA1 and pointA2
    
    if (v < 0.0 || v > 1.0)
        return NO; // intersection point not between pointB1 and pointB2
    
    CGPoint intersection;
    intersection.x = pointA1.x + u * (pointA2.x - pointA1.x);
    intersection.y = pointA1.y + u * (pointA2.y - pointA1.y);
    
    if (outIntersectionPoint) {
        *outIntersectionPoint = intersection;
    }
    
    return YES;
}



