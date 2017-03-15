//
//  GSGCellsManager.m
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/13/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import "GSGCellsManager.h"
#import "GeometryHelpers.h"
#import <PerformanceBezier/PerformanceBezier.h>



@implementation GSGCellsManager {
    NSMutableArray<GSGCell *> *_cells;
}



- (id)init {
    self = [super init];
    if (self) {
        _cells = [NSMutableArray array];
        _connectionDetectionDistance = 50.0f;
        _connectionDistance = 10.0f;
    }
    return self;
}



#pragma mark -
#pragma mark Managing cells list
- (void)addCell:(GSGCell *)cell {
    [_cells addObject:cell];
}



- (void)removeCell:(GSGCell *)cell {
    // Remove all connections with other cells before removing from array
    [self disconnectCell:cell];
    
    [_cells removeObject:cell];
}



#pragma mark -
#pragma mark Detecting connections and insertions
- (NSArray<GSGConnectionInfo *> *)getAvailableConnections {
    NSMutableArray<GSGConnectionInfo *> *connections = [NSMutableArray array];
    
    NSUInteger cellsCount = _cells.count;
    for (NSInteger fromCellIndex = 0; fromCellIndex < cellsCount; ++fromCellIndex) {
        GSGCell *cellFrom = _cells[fromCellIndex];
        
        // Cell doesn't have free connectable points
        if (![cellFrom hasAvailableConnections])
            continue;
        
        for (NSInteger toCellIndex = fromCellIndex + 1; toCellIndex < cellsCount; ++toCellIndex) {
            GSGCell *cellTo = _cells[toCellIndex];
            
            // Cell doesn't have free connectable points
            if (![cellTo hasAvailableConnections])
                continue;
            
            // Cells don't intersect
            if ([cellFrom intersectsWithCell:cellTo])
                continue;
            
            // Check left side connection
            if (![cellFrom isConnectedOnLeftSide] && ![cellTo isConnectedOnRightSide]) {
                GSGConnectionInfo *connection = [self connectionFromCell:cellFrom toCell:cellTo
                                                            fromTopPoint:kCellConnectPointLeftTop toTopPoint:kCellConnectPointRightTop
                                                         fromBottomPoint:kCellConnectPointLeftBottom toBottomPoint:kCellConnectPointRightBottom];
                if (connection) {
                    [connections addObject:connection];
                }
            }
            
            // Check right side connection
            if (![cellFrom isConnectedOnRightSide] && ![cellTo isConnectedOnLeftSide]) {
                GSGConnectionInfo *connection = [self connectionFromCell:cellFrom toCell:cellTo
                                                            fromTopPoint:kCellConnectPointRightTop toTopPoint:kCellConnectPointLeftTop
                                                         fromBottomPoint:kCellConnectPointRightBottom toBottomPoint:kCellConnectPointLeftBottom];
                if (connection) {
                    [connections addObject:connection];
                }
            }
        }
    }
    
    return connections;
}



- (GSGConnectionInfo *)connectionFromCell:(GSGCell *)cellFrom toCell:(GSGCell *)cellTo
                                 fromTopPoint:(NSInteger)fromTopPoint toTopPoint:(NSInteger)toTopPoint
                              fromBottomPoint:(NSInteger)fromBottomPoint toBottomPoint:(NSInteger)toBottomPoint {
    // Get distance between top and bottom points pairs
    float distance1 = CGPointGetDistance(cellFrom.points[fromTopPoint].position, cellTo.points[toTopPoint].position);
    float distance2 = CGPointGetDistance(cellFrom.points[fromBottomPoint].position, cellTo.points[toBottomPoint].position);
    
    // Chack points are close enough
    if (distance1 < _connectionDetectionDistance || distance2 < _connectionDetectionDistance) {
        GSGConnectionInfo *connection = [[GSGConnectionInfo alloc] init];
        connection.cellFrom = cellFrom;
        connection.cellTo = cellTo;
        connection.fromTopPointIndex = fromTopPoint;
        connection.toTopPointIndex = toTopPoint;
        connection.fromBottomPointIndex = fromBottomPoint;
        connection.toBottomPointIndex = toBottomPoint;
        
        return connection;
    }
    
    return nil;
}



- (NSArray<GSGInsertionInfo *> *)getAvailableInsertions {
    return nil;
}



#pragma mark -
#pragma mark Applying connections, insertions, movements and disconnections
- (void)connectCells:(GSGConnectionInfo *)connectionInfo {
    // 1. Calculate connection axis (line between centers of connected cells)
    CGPoint axisFrom = connectionInfo.cellFrom.centerPoint;
    CGPoint axisVector = CGPointSubtract(connectionInfo.cellTo.centerPoint, connectionInfo.cellFrom.centerPoint);
    CGPoint axisVectorNorm = CGPointNormalize(axisVector);
    float axisLength = CGPointGetLength(axisVector);
    
    // Perpendicular vec to axis directed up
    CGPoint axisUpPerpVector = CGPointMake(-axisVectorNorm.y, axisVectorNorm.x);
    if (axisUpPerpVector.y > 0) axisUpPerpVector = CGPointScale(axisUpPerpVector, -1.0f);
    
    
    // 2. Find connection center point and all involved cells points
    CGPoint centerPoint = CGPointAdd(axisFrom, CGPointScale(axisVectorNorm, axisLength * 0.5f));
    
    GSGPoint *fromTopPoint =    connectionInfo.cellFrom.points[connectionInfo.fromTopPointIndex];
    GSGPoint *toTopPoint =      connectionInfo.cellTo.points[connectionInfo.toTopPointIndex];
    GSGPoint *fromBottomPoint = connectionInfo.cellFrom.points[connectionInfo.fromBottomPointIndex];
    GSGPoint *toBottomPoint =   connectionInfo.cellTo.points[connectionInfo.toBottomPointIndex];
    
    NSInteger fromTopPointNeighbourIndex =      [GSGCell indexOfNotConnectableNeighbour:connectionInfo.fromTopPointIndex];
    NSInteger toTopPointNeighbourIndex =        [GSGCell indexOfNotConnectableNeighbour:connectionInfo.toTopPointIndex];
    NSInteger fromBottomPointNeighbourIndex =   [GSGCell indexOfNotConnectableNeighbour:connectionInfo.fromBottomPointIndex];
    NSInteger toBottomPointNeighbourIndex =     [GSGCell indexOfNotConnectableNeighbour:connectionInfo.toBottomPointIndex];
    GSGPoint *fromTopPointNeighbour =       connectionInfo.cellFrom.points[fromTopPointNeighbourIndex];
    GSGPoint *toTopPointNeighbour =         connectionInfo.cellTo.points[toTopPointNeighbourIndex];
    GSGPoint *fromBottomPointNeighbour =    connectionInfo.cellFrom.points[fromBottomPointNeighbourIndex];
    GSGPoint *toBottomPointNeighbour =      connectionInfo.cellTo.points[toBottomPointNeighbourIndex];
    
    // NEIGHBOURS MOVING METHOD 1 (simpler, but worse result) {
//    // Store relative neighbours positions to update them after moving connection points
//    CGPoint fromTopPointNeighbourRelPos = [connectionInfo.cellFrom relativeToNeighboursPointPosition:fromTopPointNeighbourIndex];
//    CGPoint toTopPointNeighbourRelPos = [connectionInfo.cellTo relativeToNeighboursPointPosition:toTopPointNeighbourIndex];
//    CGPoint fromBottomPointNeighbourRelPos = [connectionInfo.cellFrom relativeToNeighboursPointPosition:fromBottomPointNeighbourIndex];
//    CGPoint toBottomPointNeighbourRelPos = [connectionInfo.cellTo relativeToNeighboursPointPosition:toBottomPointNeighbourIndex];
    // NEIGHBOURS MOVING METHOD 1 }
    
    // NEIGHBOURS MOVING METHOD 2 (more complex, but better shape after connecting) {
    // Calculate distance to avg point between connection points of both cells
    CGPoint fromConnectionMidPoint =    CGPointScale(CGPointAdd(fromTopPoint.position, fromBottomPoint.position), 0.5f);
    CGPoint toConnectionMidPoint =      CGPointScale(CGPointAdd(toTopPoint.position, toBottomPoint.position), 0.5f);
    float fromConnectionMidDistance =   CGPointGetDistance(connectionInfo.cellFrom.centerPoint, fromConnectionMidPoint);
    float toConnectionMidDistance =     CGPointGetDistance(connectionInfo.cellTo.centerPoint, toConnectionMidPoint);
    // NEIGHBOURS MOVING METHOD 2 }
    
    
    // 3. Move connection points
    float fromConnectPointsDistance = CGPointGetDistance(fromTopPoint.position, fromBottomPoint.position);
    float toConnectPointsDistance = CGPointGetDistance(toTopPoint.position, toBottomPoint.position);
    float connectPointsDistance = MAX(fromConnectPointsDistance, toConnectPointsDistance);
//    float connectPointsDistance = (fromConnectPointsDistance + toConnectPointsDistance) * 0.5f;
    
    CGPoint (^axisAlignedPointMove)(CGPoint fromPoint, float alongAxis, float alongPerpAxis) = ^ CGPoint (CGPoint fromPoint, float alongAxis, float alongPerpAxis) {
        CGPoint point = fromPoint;
        point = CGPointAdd(point, CGPointScale(axisVectorNorm, alongAxis));
        point = CGPointAdd(point, CGPointScale(axisUpPerpVector, alongPerpAxis));
        return point;
    };
    
    // Move connection points along connection axis and perpendicularly to it
    float connectionDistanceHalf = _connectionDistance * 0.5f;
    float connectPointsDistanceHalf = connectPointsDistance * 0.5f;
    fromTopPoint.position =     axisAlignedPointMove(centerPoint, -connectionDistanceHalf, connectPointsDistanceHalf);
    fromBottomPoint.position =  axisAlignedPointMove(centerPoint, -connectionDistanceHalf, -connectPointsDistanceHalf);
    toTopPoint.position =       axisAlignedPointMove(centerPoint, connectionDistanceHalf, connectPointsDistanceHalf);
    toBottomPoint.position =    axisAlignedPointMove(centerPoint, connectionDistanceHalf, -connectPointsDistanceHalf);
    
    
    // NEIGHBOURS MOVING METHOD 1 (simpler, but worse result) {
    // 4. Move neighbour points proportionally
//    [connectionInfo.cellFrom setPointPosition:fromTopPointNeighbourIndex relativeToNeighbours:fromTopPointNeighbourRelPos];
//    [connectionInfo.cellTo setPointPosition:toTopPointNeighbourIndex relativeToNeighbours:toTopPointNeighbourRelPos];
//    [connectionInfo.cellFrom setPointPosition:fromBottomPointNeighbourIndex relativeToNeighbours:fromBottomPointNeighbourRelPos];
//    [connectionInfo.cellTo setPointPosition:toBottomPointNeighbourIndex relativeToNeighbours:toBottomPointNeighbourRelPos];
    // NEIGHBOURS MOVING METHOD 1 }
    
    // NEIGHBOURS MOVING METHOD 2 (more complex, but better shape after connecting) {
    // Calculate distance to avg point between connection neighbour points of both cells
    CGPoint fromNeighbourMidPoint =     CGPointScale(CGPointAdd(fromTopPointNeighbour.position, fromBottomPointNeighbour.position), 0.5f);
    CGPoint toNeighbourMidPoint =       CGPointScale(CGPointAdd(toTopPointNeighbour.position, toBottomPointNeighbour.position), 0.5f);
    float fromNeighbourMidDistance =    CGPointGetDistance(connectionInfo.cellFrom.centerPoint, fromNeighbourMidPoint);
    float toNeighbourMidDistance =      CGPointGetDistance(connectionInfo.cellTo.centerPoint, toNeighbourMidPoint);
    
    // Recalculate distance to avg point between connection points of both cells after moving them on step 3
    CGPoint newFromConnectionMidPoint =     CGPointScale(CGPointAdd(fromTopPoint.position, fromBottomPoint.position), 0.5f);
    CGPoint newToConnectionMidPoint =       CGPointScale(CGPointAdd(toTopPoint.position, toBottomPoint.position), 0.5f);
    float newFromConnectionMidDistance =    CGPointGetDistance(connectionInfo.cellFrom.centerPoint, newFromConnectionMidPoint);
    float newToConnectionMidDistance =      CGPointGetDistance(connectionInfo.cellTo.centerPoint, newToConnectionMidPoint);
    
    // Culculating new distance (along connection axis) from cell center to neighbour avg points (proportionally to position before step 3)
    float newFromNeighbourMidDistance =     (fromNeighbourMidDistance / fromConnectionMidDistance) * newFromConnectionMidDistance;
    float newToNeighbourMidDistance =       (toNeighbourMidDistance / toConnectionMidDistance) * newToConnectionMidDistance;
    float fromNeighbourPointsDistanceHalf = CGPointGetDistance(fromTopPointNeighbour.position, fromBottomPointNeighbour.position) * 0.5f;
    float toNeighbourPointsDistanceHalf =   CGPointGetDistance(toTopPointNeighbour.position, toBottomPointNeighbour.position) * 0.5f;
    
    // Move connection neighbour points along connection axis and perpendicularly to it
    fromTopPointNeighbour.position =    axisAlignedPointMove(connectionInfo.cellFrom.centerPoint, newFromNeighbourMidDistance, fromNeighbourPointsDistanceHalf);
    fromBottomPointNeighbour.position = axisAlignedPointMove(connectionInfo.cellFrom.centerPoint, newFromNeighbourMidDistance, -fromNeighbourPointsDistanceHalf);
    toTopPointNeighbour.position =      axisAlignedPointMove(connectionInfo.cellTo.centerPoint, -newToNeighbourMidDistance, toNeighbourPointsDistanceHalf);
    toBottomPointNeighbour.position =   axisAlignedPointMove(connectionInfo.cellTo.centerPoint, -newToNeighbourMidDistance, -toNeighbourPointsDistanceHalf);
    // NEIGHBOURS MOVING METHOD 2 }

    
    [connectionInfo.cellFrom updateBezierControlVectors];
    [connectionInfo.cellTo updateBezierControlVectors];
    
    
    // 5. Calculate distance between interpolated bezier path part (nearest A, B points)
    NSInteger fromSegmentIndex = [connectionInfo.cellFrom bezierSegmentIndexBetweenPoint1:connectionInfo.fromTopPointIndex andPoint2:connectionInfo.fromBottomPointIndex];
    NSInteger toSegmentIndex = [connectionInfo.cellTo bezierSegmentIndexBetweenPoint1:connectionInfo.toTopPointIndex andPoint2:connectionInfo.toBottomPointIndex];
    CGPoint fromBezier[4], toBezier[4];
    [connectionInfo.cellFrom.bezierPath fillBezier:fromBezier forElement:fromSegmentIndex];
    [connectionInfo.cellTo.bezierPath fillBezier:toBezier forElement:toSegmentIndex];
    
    CGPoint fromSegmentMidPoint = [UIBezierPath pointAtT:0.5f forBezier:fromBezier];
    CGPoint toSegmentMidPoint = [UIBezierPath pointAtT:0.5f forBezier:toBezier];
    float distanceAB = CGPointGetDistance(fromSegmentMidPoint, toSegmentMidPoint);
    
    
    // 6. Move connection points and neighbours so A-B = connectionDistance
    float moveDistance = (_connectionDistance - distanceAB) * 0.5f;
    
    CGPoint fromCellMoveVec =           CGPointScale(axisVectorNorm, -moveDistance);
    fromTopPoint.position =             CGPointAdd(fromTopPoint.position, fromCellMoveVec);
    fromBottomPoint.position =          CGPointAdd(fromBottomPoint.position, fromCellMoveVec);
    fromTopPointNeighbour.position =    CGPointAdd(fromTopPointNeighbour.position, fromCellMoveVec);
    fromBottomPointNeighbour.position = CGPointAdd(fromBottomPointNeighbour.position, fromCellMoveVec);
    
    CGPoint toCellMoveVec =             CGPointScale(axisVectorNorm, moveDistance);
    toTopPoint.position =               CGPointAdd(toTopPoint.position, toCellMoveVec);
    toBottomPoint.position =            CGPointAdd(toBottomPoint.position, toCellMoveVec);
    toTopPointNeighbour.position =      CGPointAdd(toTopPointNeighbour.position, toCellMoveVec);
    toBottomPointNeighbour.position =   CGPointAdd(toBottomPointNeighbour.position, toCellMoveVec);
    
    [connectionInfo.cellFrom updateBezierControlVectors];
    [connectionInfo.cellTo updateBezierControlVectors];
    
    
    // 7. Apply connection data
    [self connectCellA:connectionInfo.cellFrom toCellB:connectionInfo.cellTo
              byPointA:connectionInfo.fromTopPointIndex andPointB:connectionInfo.toTopPointIndex];
    
    [self connectCellA:connectionInfo.cellFrom toCellB:connectionInfo.cellTo
              byPointA:connectionInfo.fromBottomPointIndex andPointB:connectionInfo.toBottomPointIndex];
    
}



- (void)connectCellA:(GSGCell *)cellA toCellB:(GSGCell *)cellB byPointA:(NSInteger)pointAIndex andPointB:(NSInteger)pointBIndex {
    GSGPoint *pointA = cellA.points[pointAIndex];
    GSGPoint *pointB = cellB.points[pointBIndex];
    
    pointA.connectedCell = cellB;
    pointA.connectedPointIndex = pointBIndex;
    
    pointB.connectedCell = cellA;
    pointB.connectedPointIndex = pointAIndex;
}



- (void)insertCell:(GSGInsertionInfo *)insertionInfo {
    
}



- (void)updateCellConnections:(GSGCell *)cell {
    
}



- (void)disconnectCell:(GSGCell *)cell {
    
}

@end
