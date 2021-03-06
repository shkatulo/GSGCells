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

const NSUInteger kCellConnectPointLeftTopNeighbour = 1;
const NSUInteger kCellConnectPointLeftBottomNeighbour = 6;
const NSUInteger kCellConnectPointRightTopNeighbour = 2;
const NSUInteger kCellConnectPointRightBottomNeighbour = 5;



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
    _bezierPath = [self bezierPathRelativeToPoint:CGPointZero closed:YES];
    
    // Update bounding box
    _boundingBox = _bezierPath.bounds;
    
    _needUpdateBezierPath = NO;
    return _bezierPath;
}



- (UIBezierPath *)bezierPathRelativeToPoint:(CGPoint)point closed:(BOOL)closed {
    return [GSGCell bezierPathFromPoints:_points relativeToPoint:point closed:closed];
}



+ (UIBezierPath *)bezierPathFromPoints:(NSArray<GSGPoint *> *)points relativeToPoint:(CGPoint)point closed:(BOOL)closed {
    UIBezierPath *path = [[UIBezierPath alloc] init];
    
    NSInteger segmentsCount = closed ? points.count : points.count - 1;
    for (NSInteger i = 0; i < segmentsCount; ++i) {
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
    CGPoint center = CGPointAdd(_points[kCellConnectPointLeftTopNeighbour].position, _points[kCellConnectPointLeftBottomNeighbour].position);
    center = CGPointAdd(center, _points[kCellConnectPointRightTopNeighbour].position);
    center = CGPointAdd(center, _points[kCellConnectPointRightBottomNeighbour].position);
    center = CGPointScale(center, 0.25f);
    return center;
}



- (CGPoint)boundingBoxCenter {
    return CGPointMake(CGRectGetMidX(self.boundingBox), CGRectGetMidY(self.boundingBox));
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
    if (connectablePointIndex == kCellConnectPointLeftTop) return kCellConnectPointLeftTopNeighbour;
    else if (connectablePointIndex == kCellConnectPointRightTop) return kCellConnectPointRightTopNeighbour;
    else if (connectablePointIndex == kCellConnectPointLeftBottom) return kCellConnectPointLeftBottomNeighbour;
    else if (connectablePointIndex == kCellConnectPointRightBottom) return kCellConnectPointRightBottomNeighbour;
    
    return NSNotFound;
}



+ (NSInteger)indexOfConnectablePointToPoint:(NSInteger)pointIndex {
    if (pointIndex == kCellConnectPointLeftTop ||
        pointIndex == kCellConnectPointRightTop ||
        pointIndex == kCellConnectPointLeftBottom ||
        pointIndex == kCellConnectPointRightBottom) {
        return [GSGCell indexOfOppositeSidePoint:pointIndex];
    }
    
    return NSNotFound;
}



+ (NSInteger)indexOfOppositeSidePoint:(NSInteger)pointIndex {
    if (pointIndex == kCellConnectPointLeftTop) return kCellConnectPointRightTop;
    else if (pointIndex == kCellConnectPointRightTop) return kCellConnectPointLeftTop;
    else if (pointIndex == kCellConnectPointLeftBottom) return kCellConnectPointRightBottom;
    else if (pointIndex == kCellConnectPointRightBottom) return kCellConnectPointLeftBottom;
    
    if (pointIndex == kCellConnectPointLeftTopNeighbour) return kCellConnectPointRightTopNeighbour;
    else if (pointIndex == kCellConnectPointRightTopNeighbour) return kCellConnectPointLeftTopNeighbour;
    else if (pointIndex == kCellConnectPointLeftBottomNeighbour) return kCellConnectPointRightBottomNeighbour;
    else if (pointIndex == kCellConnectPointRightBottomNeighbour) return kCellConnectPointLeftBottomNeighbour;
    
    return NSNotFound;
}



+ (BOOL)isTopConnectablePoint:(NSInteger)pointIndex {
    return (pointIndex == kCellConnectPointLeftTop || pointIndex == kCellConnectPointRightTop);
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



- (BOOL)isConnectedToCell:(GSGCell *)cell {
    for (int i = 0; i < _points.count; ++i) {
        GSGPoint *point = _points[i];
        if (point.connectedCell == cell) {
            return YES;
        }
    }
    return NO;
}



- (void)moveBy:(CGPoint)moveVector {
    for (int i = 0; i < _points.count; ++i) {
        GSGPoint *point = _points[i];
        point.position = CGPointAdd(point.position, moveVector);
    }
}

@end
