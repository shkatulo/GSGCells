//
//  GSGPoint.h
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/10/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import <UIKit/UIKit.h>



@class GSGCell;



@interface GSGPoint : NSObject

@property (nonatomic) CGPoint position;

@property (nonatomic) CGPoint prevControlVec;
@property (nonatomic) CGPoint nextControlVec;

@property (nonatomic, weak) GSGCell *connectedCell;
@property (nonatomic) NSInteger connectedPointIndex;



- (id)initWithPosition:(CGPoint)position;

- (BOOL)isConnected;

- (CGPoint)positionRelativeToPoint:(CGPoint)point;
- (CGPoint)prevControlPointRelativeToPoint:(CGPoint)point;
- (CGPoint)nextControlPointRelativeToPoint:(CGPoint)point;

@end
