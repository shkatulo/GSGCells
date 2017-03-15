//
//  GSGCell.m
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/10/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import "GSGCell.h"
#import "GeometryHelpers.h"



#define POINTS_COUNT 8

#define CONTROL_POINTS_DIVIDER 6.0f



const NSUInteger kCellConnectPointLeftTop = 0;
const NSUInteger kCellConnectPointLeftBottom = 7;
const NSUInteger kCellConnectPointRightTop = 3;
const NSUInteger kCellConnectPointRightBottom = 4;



@implementation GSGCell {
    NSMutableArray<GSGPoint *> *_points;
    UIBezierPath *_bezierPath;
    BOOL _needUpdateBezierPath;
}

@synthesize boundingBox = _boundingBox;



- (id)initAtPoint:(CGPoint)point {
    self = [self init];
    if (self) {
        _udid = [NSUUID UUID].UUIDString;
        
        // Allocate curve points
        _points = [NSMutableArray array];
        for (int i = 0; i < POINTS_COUNT; ++i) {
            [_points addObject: [[GSGPoint alloc] init] ];
        }
        
        // Initialize shape
        [self initialiseShape:0 aroundPoint:point];
    }
    return self;
}



#pragma mark -
#pragma mark Points
- (void)initialiseShape:(int)shapeIndex aroundPoint:(CGPoint)p {
    NSMutableArray *geometry = [NSMutableArray arrayWithCapacity:POINTS_COUNT];
    
    if (shapeIndex == 0) {
        [geometry addObject: [NSValue valueWithCGPoint:CGPointMake(p.x - 55, p.y - 30)] ];
        [geometry addObject: [NSValue valueWithCGPoint:CGPointMake(p.x - 30, p.y - 60)] ];
        [geometry addObject: [NSValue valueWithCGPoint:CGPointMake(p.x + 25, p.y - 60)] ];
        [geometry addObject: [NSValue valueWithCGPoint:CGPointMake(p.x + 50, p.y - 20)] ];
        [geometry addObject: [NSValue valueWithCGPoint:CGPointMake(p.x + 45, p.y + 20)] ];
        [geometry addObject: [NSValue valueWithCGPoint:CGPointMake(p.x + 25, p.y + 45)] ];
        [geometry addObject: [NSValue valueWithCGPoint:CGPointMake(p.x - 25, p.y + 45)] ];
        [geometry addObject: [NSValue valueWithCGPoint:CGPointMake(p.x - 50, p.y + 20)] ];
    }
    else if (shapeIndex == 1) {
        [geometry addObject: [NSValue valueWithCGPoint:CGPointMake(p.x - 55, p.y - 20)] ];
        [geometry addObject: [NSValue valueWithCGPoint:CGPointMake(p.x - 40, p.y - 50)] ];
        [geometry addObject: [NSValue valueWithCGPoint:CGPointMake(p.x + 30, p.y - 50)] ];
        [geometry addObject: [NSValue valueWithCGPoint:CGPointMake(p.x + 65, p.y - 20)] ];
        [geometry addObject: [NSValue valueWithCGPoint:CGPointMake(p.x + 65, p.y + 20)] ];
        [geometry addObject: [NSValue valueWithCGPoint:CGPointMake(p.x + 40, p.y + 35)] ];
        [geometry addObject: [NSValue valueWithCGPoint:CGPointMake(p.x - 35, p.y + 35)] ];
        [geometry addObject: [NSValue valueWithCGPoint:CGPointMake(p.x - 55, p.y + 10)] ];
    }
    
    [self setGeometryData:geometry];
}



- (NSArray<NSValue *> *)geometryData {
    NSMutableArray<NSValue *> *geometry = [NSMutableArray array];
    
    for (int i = 0; i < _points.count; ++i) {
        NSValue *pointVal = [NSValue valueWithCGPoint:_points[i].position];
        [geometry addObject:pointVal];
    }
    
    return geometry;
}



- (void)setGeometryData:(NSArray<NSValue *> *)geometry {
    if (geometry.count != POINTS_COUNT) {
        NSLog(@"Invalid points count. Array must contain %d points", POINTS_COUNT);
        return;
    }
    
    for (int i = 0; i < POINTS_COUNT; ++i) {
        _points[i].position = geometry[i].CGPointValue;
    }
    
    [self updateBezierControlVectors];
}



- (void)updateBezierControlVectors {
    for (int i = 0; i < _points.count; ++i) {
        GSGPoint *currPoint = _points[i];
        GSGPoint *prevPoint = (i > 0) ? _points[i - 1] : _points[_points.count - 1];
        GSGPoint *nextPoint = _points[(i + 1) % _points.count];
        
        CGPoint nextCtrlPointVec;
        nextCtrlPointVec.x = ((nextPoint.position.x - currPoint.position.x) + (currPoint.position.x - prevPoint.position.x)) / CONTROL_POINTS_DIVIDER;
        nextCtrlPointVec.y = ((nextPoint.position.y - currPoint.position.y) + (currPoint.position.y - prevPoint.position.y)) / CONTROL_POINTS_DIVIDER;
        
        currPoint.nextControlVec = nextCtrlPointVec;
        currPoint.prevControlVec = CGPointMake(-nextCtrlPointVec.x, -nextCtrlPointVec.y);
    }
    
    _needUpdateBezierPath = YES;
}



#pragma mark -
#pragma mark Bezier path
- (UIBezierPath *)bezierPath {
    if (!_needUpdateBezierPath && _bezierPath != nil)
        return _bezierPath;

    // Update bezier path
    _bezierPath = [self bezierPathRelativeToPoint:CGPointZero];
    
    // Update bounding box
    _boundingBox = _bezierPath.bounds;
    
    _needUpdateBezierPath = NO;
    return _bezierPath;
}



- (UIBezierPath *)bezierPathRelativeToPoint:(CGPoint)point {
    return [GSGCell bezierPathFromPoints:_points relativeToPoint:point];
}



+ (UIBezierPath *)bezierPathFromPoints:(NSArray<GSGPoint *> *)points relativeToPoint:(CGPoint)point {
    UIBezierPath *path = [[UIBezierPath alloc] init];
    
    for (int i = 0; i < points.count; ++i) {
        GSGPoint *currPoint = points[i];
        GSGPoint *nextPoint = points[(i + 1) % points.count];
        
        if (i == 0) {
            CGPoint currCGPoint = [currPoint positionRelativeToPoint:point];
            [path moveToPoint:currCGPoint];
        }
        
        CGPoint ctrl1CGPoint = [currPoint nextControlPointRelativeToPoint:point];
        CGPoint ctrl2CGPoint = [nextPoint prevControlPointRelativeToPoint:point];
        CGPoint nextCGPoint = [nextPoint positionRelativeToPoint:point];
        
        [path addCurveToPoint:nextCGPoint controlPoint1:ctrl1CGPoint controlPoint2:ctrl2CGPoint];
    }
    
    return path;
}



- (CGRect)boundingBox {
    [self bezierPath]; // Update bezier path if needed
    
    return _bezierPath.bounds;
}



- (CGPoint)centerPoint {
    return CGPointMake(CGRectGetMidX(_boundingBox), CGRectGetMidY(_boundingBox));
}



#pragma mark -
#pragma mark Helpers
- (BOOL)hasConnections {
    for (int i = 0; i < _points.count; ++i) {
        GSGPoint *point = _points[i];
        if (point.isConnected) {
            return YES;
        }
    }
    return NO;
}



- (BOOL)isConnectedOnLeftSide {
    return _points[kCellConnectPointLeftTop].isConnected || _points[kCellConnectPointLeftBottom].isConnected;
}



- (BOOL)isConnectedOnRightSide {
    return _points[kCellConnectPointRightTop].isConnected || _points[kCellConnectPointRightBottom].isConnected;
}



- (BOOL)hasAvailableConnections {
    return ![self isConnectedOnLeftSide] || ![self isConnectedOnRightSide];
}



+ (NSInteger)indexOfNotConnectableNeighbour:(NSInteger)connectablePointIndex {
    if (connectablePointIndex == kCellConnectPointLeftTop) return connectablePointIndex + 1;
    else if (connectablePointIndex == kCellConnectPointRightTop) return connectablePointIndex - 1;
    else if (connectablePointIndex == kCellConnectPointLeftBottom) return connectablePointIndex - 1;
    else if (connectablePointIndex == kCellConnectPointRightBottom) return connectablePointIndex + 1;
    
    return NSNotFound;
}



- (CGPoint)relativeToNeighboursPointPosition:(NSInteger)pointIndex {
    NSInteger prevNeighbourIndex = (pointIndex > 0) ? (pointIndex - 1) : (_points.count - 1);
    NSInteger nextNeighbourIndex = (pointIndex + 1) % _points.count;
    
    CGPoint full = CGPointSubtract(_points[nextNeighbourIndex].position, _points[prevNeighbourIndex].position);
    CGPoint part = CGPointSubtract(_points[pointIndex].position, _points[prevNeighbourIndex].position);
    
    return CGPointDivide(part, full);
}



- (void)setPointPosition:(NSInteger)pointIndex relativeToNeighbours:(CGPoint)position {
    NSInteger prevNeighbourIndex = (pointIndex > 0) ? (pointIndex - 1) : (_points.count - 1);
    NSInteger nextNeighbourIndex = (pointIndex + 1) % _points.count;
    
    CGPoint full = CGPointSubtract(_points[nextNeighbourIndex].position, _points[prevNeighbourIndex].position);
    CGPoint part = CGPointMultiply(position, full);
    
    _points[pointIndex].position = CGPointAdd(_points[prevNeighbourIndex].position, part);
}



- (NSInteger)bezierSegmentIndexBetweenPoint1:(NSInteger)point1Index andPoint2:(NSInteger)point2Index {
    NSInteger minIndex = MIN(point1Index, point2Index);
    NSInteger maxIndex = MAX(point1Index, point2Index);
    
    // First segment is moveToPoint, skip it
    if (minIndex == 0 && maxIndex == _points.count - 1) {
        return _points.count;
    }
    else {
        return minIndex + 1;
    }
}



- (BOOL)intersectsWithCell:(GSGCell *)cell {
    // Check bounding boxes
    if (!CGRectIntersectsRect(self.boundingBox, cell.boundingBox))
        return NO;
    
    // Check paths
    BOOL pathIntersects = UIBezierPathGetFirstIntersection(self.bezierPath, cell.bezierPath, 4, NULL);
    return pathIntersects;
}

@end
