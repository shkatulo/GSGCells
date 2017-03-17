//
//  GSGCellsManager.m
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/13/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import "GSGCellsManager.h"
#import "GeometryHelpers.h"



#define CONNECTION_TO_NEIGHBOUR_DIST_RATIO 0.5f



@implementation GSGCellsManager {
    NSMutableArray<GSGCell *> *_cells;
}



- (id)init {
    self = [super init];
    if (self) {
        _cells = [NSMutableArray array];
        _connectionDetectionDistance = 50.0f;
        _connectionDistance = 10.0f;
        _minInsertionDistance = 100;
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
    NSMutableArray<GSGCell *> *affectedCells = [NSMutableArray array];
    
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
            
            // Cells intersect
            if ([cellFrom intersectsWithCell:cellTo])
                continue;
            
            // Check left side connection
            if (![cellFrom isConnectedOnLeftSide] && ![cellTo isConnectedOnRightSide]) {
                GSGConnectionInfo *connection = [self connectionFromCell:cellFrom toCell:cellTo
                                                            fromTopPoint:kCellConnectPointLeftTop toTopPoint:kCellConnectPointRightTop
                                                         fromBottomPoint:kCellConnectPointLeftBottom toBottomPoint:kCellConnectPointRightBottom];
                if (connection) {
                    [connections addObject:connection];
                    if (![affectedCells containsObject:cellFrom]) [affectedCells addObject:cellFrom];
                    if (![affectedCells containsObject:cellTo]) [affectedCells addObject:cellTo];
                }
            }
            
            // Check right side connection
            if (![cellFrom isConnectedOnRightSide] && ![cellTo isConnectedOnLeftSide]) {
                GSGConnectionInfo *connection = [self connectionFromCell:cellFrom toCell:cellTo
                                                            fromTopPoint:kCellConnectPointRightTop toTopPoint:kCellConnectPointLeftTop
                                                         fromBottomPoint:kCellConnectPointRightBottom toBottomPoint:kCellConnectPointLeftBottom];
                if (connection) {
                    [connections addObject:connection];
                    if (![affectedCells containsObject:cellFrom]) [affectedCells addObject:cellFrom];
                    if (![affectedCells containsObject:cellTo]) [affectedCells addObject:cellTo];
                }
            }
        }
    }
    
    // Leave only shortest connection for each cell if duplicates exist
    NSMutableArray<GSGConnectionInfo *> *shortestConnections = [NSMutableArray array];
    for (GSGCell *cell in affectedCells) {
        // Find shortest left and right side connections
        GSGConnectionInfo *shortestLeftConnection = nil;
        GSGConnectionInfo *shortestRightConnection = nil;
        float shortestLeftConnectionDistance = MAXFLOAT;
        float shortestRightConnectionDistance = MAXFLOAT;
        
        for (GSGConnectionInfo *connectionInfo in connections) {
            // Left side connection
            if ((connectionInfo.cellFrom == cell && ![connectionInfo isFromRightToLeft]) ||
                (connectionInfo.cellTo == cell && [connectionInfo isFromRightToLeft])) {
                float distance = MIN(connectionInfo.distanceTop, connectionInfo.distanceBottom);
                
                if (distance < shortestLeftConnectionDistance) {
                    shortestLeftConnection = connectionInfo;
                    shortestLeftConnectionDistance = distance;
                }
            }
            
            // Right side connection
            if ((connectionInfo.cellFrom == cell && [connectionInfo isFromRightToLeft]) ||
                (connectionInfo.cellTo == cell && ![connectionInfo isFromRightToLeft])) {
                float distance = MIN(connectionInfo.distanceTop, connectionInfo.distanceBottom);
                
                if (distance < shortestRightConnectionDistance) {
                    shortestRightConnection = connectionInfo;
                    shortestRightConnectionDistance = distance;
                }
            }
        }
        
        // Add shortest connections to result
        if (shortestLeftConnection && ![shortestConnections containsObject:shortestLeftConnection]) {
            [shortestConnections addObject:shortestLeftConnection];
        }
        if (shortestRightConnection && ![shortestConnections containsObject:shortestRightConnection]) {
            [shortestConnections addObject:shortestRightConnection];
        }
    }
    
    return shortestConnections;
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
        connection.distanceTop = distance1;
        connection.distanceBottom = distance2;
        
        return connection;
    }
    
    return nil;
}



- (NSArray<GSGInsertionInfo *> *)getAvailableInsertions {
    NSMutableArray<GSGInsertionInfo *> *insertions = [NSMutableArray array];
    
    NSUInteger cellsCount = _cells.count;
    for (NSInteger insertingCellIndex = 0; insertingCellIndex < cellsCount; ++insertingCellIndex) {
        GSGCell *insertingCell = _cells[insertingCellIndex];
        
        // Inserting cell must not have any connections
        if ([insertingCell hasConnections])
            continue;
        
        // Find overlapped cells which have connections
        NSMutableArray<GSGCell *> *overlappedCells = [NSMutableArray array];
        for (NSInteger overlapCellIndex = 0; overlapCellIndex < cellsCount; ++overlapCellIndex) {
            // Can't overlap with itself
            if (overlapCellIndex == insertingCellIndex)
                continue;
            
            GSGCell *overlapCell = _cells[overlapCellIndex];
            
            // Ignore cells which don't have any connections
            if (![overlapCell hasConnections])
                continue;
            
            // Check if cells are actually overlapped
            if (!UIBezierPathGetFirstIntersection(insertingCell.bezierPath, overlapCell.bezierPath, 4, NULL))
                continue;
            
            [overlappedCells addObject:overlapCell];
        }
        
        NSInteger overlappedCellsCount = overlappedCells.count;
        if (overlappedCellsCount < 2)
            continue;
        
        // Find connected pairs in overlapped cells array
        NSMutableArray<NSArray<GSGCell *> *> *connectedCellPairs = [NSMutableArray array];
        for (NSInteger connectedCellIndex1 = 0; connectedCellIndex1 < overlappedCellsCount; ++connectedCellIndex1) {
            for (NSInteger connectedCellIndex2 = connectedCellIndex1 + 1; connectedCellIndex2 < overlappedCellsCount; ++connectedCellIndex2) {
                GSGCell *connectedCell1 = overlappedCells[connectedCellIndex1];
                GSGCell *connectedCell2 = overlappedCells[connectedCellIndex2];
                
                // Ignore cells if they are not connected
                if (![connectedCell1 isConnectedToCell:connectedCell2])
                    continue;
                
                NSArray<GSGCell *> *connectedPair = @[ connectedCell1, connectedCell2 ];
                [connectedCellPairs addObject:connectedPair];
            }
        }
        
        NSInteger connectedPairsCount = connectedCellPairs.count;
        if (connectedPairsCount == 0)
            continue;
        
        // Find nearest pair for shortest insertion
        NSArray<GSGCell *> *nearestPair = nil;
        float nearestPairDistance = MAXFLOAT;
        for (NSInteger pairIndex = 0; pairIndex < connectedPairsCount; ++pairIndex) {
            NSArray<GSGCell *> *pair =connectedCellPairs[pairIndex];
            
            CGPoint midPoint = CGPointScale(CGPointAdd(pair[0].centerPoint, pair[1].centerPoint), 0.5f);
            float distance = CGPointGetDistance(insertingCell.centerPoint, midPoint);
            
            if (distance < nearestPairDistance) {
                nearestPair = pair;
                nearestPairDistance = distance;
            }
        }
        
        // Check insertion distance
        float insertionPairDistance = CGPointGetDistance(nearestPair[0].centerPoint, nearestPair[1].centerPoint);
        if (insertionPairDistance < _minInsertionDistance) {
            NSLog(@"Can't insert, not enough free space between cells");
            continue;
        }
        
        // Add nearest pair to available insertions
        GSGInsertionInfo *insertionInfo = [[GSGInsertionInfo alloc] initWithInsertingCell:insertingCell
                                                                                    cellA:nearestPair[0]
                                                                                    cellB:nearestPair[1]];
        [insertions addObject:insertionInfo];
    }
    
    return insertions;
}



#pragma mark -
#pragma mark Applying connections, insertions, movements and disconnections
- (void)connectCells:(GSGConnectionInfo *)connectionInfo {
    [self connectCells:connectionInfo
    withCellFromCenter:connectionInfo.cellFrom.centerPoint
          cellToCenter:connectionInfo.cellTo.centerPoint];
}



- (void)connectCells:(GSGConnectionInfo *)connectionInfo withCellFromCenter:(CGPoint)cellFromCenter cellToCenter:(CGPoint)cellToCenter {
    // 1. Update geometry
    [self updateCellsConnectionGeometry:connectionInfo
                     withCellFromCenter:cellFromCenter
                           cellToCenter:cellToCenter];
    
    // 2. Apply connection data
    [self connectCellA:connectionInfo.cellFrom toCellB:connectionInfo.cellTo
              byPointA:connectionInfo.fromTopPointIndex andPointB:connectionInfo.toTopPointIndex];
    
    [self connectCellA:connectionInfo.cellFrom toCellB:connectionInfo.cellTo
              byPointA:connectionInfo.fromBottomPointIndex andPointB:connectionInfo.toBottomPointIndex];
    
}



- (void)updateCellsConnectionGeometry:(GSGConnectionInfo *)connectionInfo withCellFromCenter:(CGPoint)cellFromCenter cellToCenter:(CGPoint)cellToCenter {
    // 1. Calculate connection axis (line between centers of connected cells)
    CGPoint axisFrom = cellFromCenter;
    CGPoint axisVector = CGPointSubtract(cellToCenter, cellFromCenter);
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
    
    NSInteger fromTopPointNeighbourOppositeIndex =      [GSGCell indexOfOppositeSidePoint:fromTopPointNeighbourIndex];
    NSInteger toTopPointNeighbourOppositeIndex =        [GSGCell indexOfOppositeSidePoint:toTopPointNeighbourIndex];
    NSInteger fromBottomPointNeighbourOppositeIndex =   [GSGCell indexOfOppositeSidePoint:fromBottomPointNeighbourIndex];
    NSInteger toBottomPointNeighbourOppositeIndex =     [GSGCell indexOfOppositeSidePoint:toBottomPointNeighbourIndex];
    GSGPoint *fromTopPointNeighbourOpposite =       connectionInfo.cellFrom.points[fromTopPointNeighbourOppositeIndex];
    GSGPoint *toTopPointNeighbourOpposite =         connectionInfo.cellTo.points[toTopPointNeighbourOppositeIndex];
    GSGPoint *fromBottomPointNeighbourOpposite =    connectionInfo.cellFrom.points[fromBottomPointNeighbourOppositeIndex];
    GSGPoint *toBottomPointNeighbourOpposite =      connectionInfo.cellTo.points[toBottomPointNeighbourOppositeIndex];
    
    
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
    
    
    // 4. Move neighbour points proportionally
    // Calculate distance to avg point between connection points of both cells after moving them on step 3
    CGPoint fromConnectionMidPoint =     CGPointScale(CGPointAdd(fromTopPoint.position, fromBottomPoint.position), 0.5f);
    CGPoint toConnectionMidPoint =       CGPointScale(CGPointAdd(toTopPoint.position, toBottomPoint.position), 0.5f);
    float fromConnectionMidDistance =    CGPointGetDistance(cellFromCenter, fromConnectionMidPoint);
    float toConnectionMidDistance =      CGPointGetDistance(cellToCenter, toConnectionMidPoint);
    
    // Culculating new distance (along connection axis) from cell center to neighbour avg points (proportionally to position before step 3)
    float fromNeighbourMidDistance =     CONNECTION_TO_NEIGHBOUR_DIST_RATIO * fromConnectionMidDistance;
    float toNeighbourMidDistance =       CONNECTION_TO_NEIGHBOUR_DIST_RATIO * toConnectionMidDistance;
    float fromNeighbourPointsDistanceHalf = CGPointGetDistance(fromTopPointNeighbour.position, fromBottomPointNeighbour.position) * 0.5f;
    float toNeighbourPointsDistanceHalf =   CGPointGetDistance(toTopPointNeighbour.position, toBottomPointNeighbour.position) * 0.5f;
    
    // Move connection neighbour points along connection axis and perpendicularly to it
    fromTopPointNeighbour.position =    axisAlignedPointMove(cellFromCenter, fromNeighbourMidDistance, fromNeighbourPointsDistanceHalf);
    fromBottomPointNeighbour.position = axisAlignedPointMove(cellFromCenter, fromNeighbourMidDistance, -fromNeighbourPointsDistanceHalf);
    toTopPointNeighbour.position =      axisAlignedPointMove(cellToCenter, -toNeighbourMidDistance, toNeighbourPointsDistanceHalf);
    toBottomPointNeighbour.position =   axisAlignedPointMove(cellToCenter, -toNeighbourMidDistance, -toNeighbourPointsDistanceHalf);
    
    // Check if connection neighbour does not go behind other side neighbour (sometimes happens, when cell is very tall and connected cells have big Y-delta)
    BOOL isFromTopNeighbourOnTheRight =         CGPointIsOnTheRightSideOfLine(fromTopPointNeighbour.position, fromBottomPointNeighbourOpposite.position, fromTopPointNeighbourOpposite.position);
    BOOL isFromBottomNeighbourOnTheRight =      CGPointIsOnTheRightSideOfLine(fromBottomPointNeighbour.position, fromBottomPointNeighbourOpposite.position, fromTopPointNeighbourOpposite.position);
    BOOL isFromConnectionMidPointOnTheRight =   CGPointIsOnTheRightSideOfLine(fromConnectionMidPoint, fromBottomPointNeighbourOpposite.position, fromTopPointNeighbourOpposite.position);
    if (isFromConnectionMidPointOnTheRight != isFromTopNeighbourOnTheRight) { // connection and neighbour are on different sides
//        fromTopPointNeighbour.position = CGPointScale(CGPointAdd(fromTopPoint.position, fromTopPointNeighbourOpposite.position), 0.5f);
        fromTopPointNeighbour.position = fromTopPointNeighbourOpposite.position;
    }
    if (isFromConnectionMidPointOnTheRight != isFromBottomNeighbourOnTheRight) { // connection and neighbour are on different sides
//        fromBottomPointNeighbour.position = CGPointScale(CGPointAdd(fromBottomPoint.position, fromBottomPointNeighbourOpposite.position), 0.5f);
        fromBottomPointNeighbour.position = fromBottomPointNeighbourOpposite.position;
    }
    
    BOOL isToTopNeighbourOnTheRight =         CGPointIsOnTheRightSideOfLine(toTopPointNeighbour.position, toBottomPointNeighbourOpposite.position, toTopPointNeighbourOpposite.position);
    BOOL isToBottomNeighbourOnTheRight =      CGPointIsOnTheRightSideOfLine(toBottomPointNeighbour.position, toBottomPointNeighbourOpposite.position, toTopPointNeighbourOpposite.position);
    BOOL isToConnectionMidPointOnTheRight =   CGPointIsOnTheRightSideOfLine(toConnectionMidPoint, toBottomPointNeighbourOpposite.position, toTopPointNeighbourOpposite.position);
    if (isToConnectionMidPointOnTheRight != isToTopNeighbourOnTheRight) { // connection and neighbour are on different sides
//        toTopPointNeighbour.position = CGPointScale(CGPointAdd(toTopPoint.position, toTopPointNeighbourOpposite.position), 0.5f);
        toTopPointNeighbour.position = toTopPointNeighbourOpposite.position;
    }
    if (isToConnectionMidPointOnTheRight != isToBottomNeighbourOnTheRight) { // connection and neighbour are on different sides
//        toBottomPointNeighbour.position = CGPointScale(CGPointAdd(toBottomPoint.position, toBottomPointNeighbourOpposite.position), 0.5f);
        toBottomPointNeighbour.position = toBottomPointNeighbourOpposite.position;
    }
    
    
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
    // 1. Place inserting cell between cell A and cell B
    CGPoint insertionMidPoint = CGPointScale(CGPointAdd(insertionInfo.cellA.centerPoint, insertionInfo.cellB.centerPoint), 0.5f);
    CGPoint moveVector = CGPointSubtract(insertionMidPoint, insertionInfo.insertingCell.centerPoint);
    [insertionInfo.insertingCell moveBy:moveVector];
    
    [insertionInfo.insertingCell updateBezierControlVectors];
    
    
    // 2. Create and apply connection to cell A (or use existing)
    GSGConnectionInfo *connectionInfo = insertionInfo.connectionA;
    if (connectionInfo == nil) {
        connectionInfo = [[GSGConnectionInfo alloc] init];
        connectionInfo.cellFrom = insertionInfo.insertingCell;
        connectionInfo.cellTo = insertionInfo.cellA;
        
        for (NSInteger i = 0; i < connectionInfo.cellTo.points.count; ++i) {
            GSGPoint *point = connectionInfo.cellTo.points[i];
            
            // Ignore not connected points and points connected to cells not from insertion pair
            if (point.connectedCell != insertionInfo.cellB)
                continue;
            
            if ([GSGCell isTopConnectablePoint:i]) {
                connectionInfo.fromTopPointIndex = [GSGCell indexOfConnectablePointToPoint:i];
                connectionInfo.toTopPointIndex = i;
            }
            else {
                connectionInfo.fromBottomPointIndex = [GSGCell indexOfConnectablePointToPoint:i];
                connectionInfo.toBottomPointIndex = i;
            }
        }
    }
    
    [self connectCells:connectionInfo
    withCellFromCenter:insertionMidPoint
          cellToCenter:connectionInfo.cellTo.centerPoint];
    
    
    // 3. Create and apply connection to cell B (or use existing)
    connectionInfo = insertionInfo.connectionB;
    if (connectionInfo == nil) {
        connectionInfo = [[GSGConnectionInfo alloc] init];
        connectionInfo.cellFrom = insertionInfo.insertingCell;
        connectionInfo.cellTo = insertionInfo.cellB;
        
        for (NSInteger i = 0; i < connectionInfo.cellTo.points.count; ++i) {
            GSGPoint *point = connectionInfo.cellTo.points[i];
            
            // Ignore not connected points and points connected to cells not from insertion pair
            if (point.connectedCell != insertionInfo.cellA)
                continue;
            
            if ([GSGCell isTopConnectablePoint:i]) {
                connectionInfo.fromTopPointIndex = [GSGCell indexOfConnectablePointToPoint:i];
                connectionInfo.toTopPointIndex = i;
            }
            else {
                connectionInfo.fromBottomPointIndex = [GSGCell indexOfConnectablePointToPoint:i];
                connectionInfo.toBottomPointIndex = i;
            }
        }
    }
    
    [self connectCells:connectionInfo
    withCellFromCenter:insertionMidPoint
          cellToCenter:connectionInfo.cellTo.centerPoint];
}



- (void)disconnectCell:(GSGCell *)cell {
}

@end
