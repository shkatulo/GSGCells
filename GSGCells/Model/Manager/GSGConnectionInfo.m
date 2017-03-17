//
//  GSGConnectionInfo.m
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/13/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import "GSGConnectionInfo.h"



@implementation GSGConnectionInfo

- (GSGCell *)commonCellWithOtherConnection:(GSGConnectionInfo *)connection {
    if (_cellFrom == connection.cellFrom) return _cellFrom;
    if (_cellFrom == connection.cellTo) return _cellFrom;
    if (_cellTo == connection.cellFrom) return _cellTo;
    if (_cellTo == connection.cellTo) return _cellTo;
    
    return nil;
}



- (void)invert {
    GSGCell *tmpCell = _cellFrom;
    _cellFrom = _cellTo;
    _cellTo = tmpCell;
    
    NSInteger tmpIndex = _fromTopPointIndex;
    _fromTopPointIndex = _toTopPointIndex;
    _toTopPointIndex = tmpIndex;
    
    tmpIndex = _fromBottomPointIndex;
    _fromBottomPointIndex = _toBottomPointIndex;
    _toBottomPointIndex = tmpIndex;
}



- (NSArray<GSGPoint *> *)affectedPoints {
    NSMutableArray<GSGPoint *> *points = [NSMutableArray array];
    
    [points addObject:_cellFrom.points[_fromTopPointIndex]];
    [points addObject:_cellFrom.points[_fromBottomPointIndex]];
    [points addObject:_cellTo.points[_toTopPointIndex]];
    [points addObject:_cellTo.points[_toBottomPointIndex]];
    
    return points;
}



- (BOOL)isFromRightToLeft {
    return (_fromTopPointIndex == kCellConnectPointRightTop &&
            _fromBottomPointIndex == kCellConnectPointRightBottom);
}

@end
