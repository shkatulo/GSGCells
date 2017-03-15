//
//  GSGPoint.m
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/10/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import "GSGPoint.h"



@implementation GSGPoint



- (id)init {
    self = [super init];
    if (self) {
        _connectedPointIndex = NSNotFound;
    }
    return self;
}



- (id)initWithPosition:(CGPoint)position {
    self = [self init];
    if (self) {
        _position = position;
    }
    return self;
}



- (BOOL)isConnected {
    return (_connectedCell != nil && _connectedPointIndex != NSNotFound);
}



- (CGPoint)positionRelativeToPoint:(CGPoint)point {
    return CGPointMake(_position.x - point.x, _position.y - point.y);
}



- (CGPoint)prevControlPointRelativeToPoint:(CGPoint)point {
    return CGPointMake(_position.x + _prevControlVec.x - point.x, _position.y + _prevControlVec.y - point.y);
}



- (CGPoint)nextControlPointRelativeToPoint:(CGPoint)point {
    return CGPointMake(_position.x + _nextControlVec.x - point.x, _position.y + _nextControlVec.y - point.y);
}

@end
