//
//  GSGCell.h
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/10/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GSGPoint.h"



extern const NSUInteger kCellConnectPointLeftTop;
extern const NSUInteger kCellConnectPointLeftBottom;
extern const NSUInteger kCellConnectPointRightTop;
extern const NSUInteger kCellConnectPointRightBottom;

extern const NSUInteger kCellConnectPointLeftTopNeighbour;
extern const NSUInteger kCellConnectPointLeftBottomNeighbour;
extern const NSUInteger kCellConnectPointRightTopNeighbour;
extern const NSUInteger kCellConnectPointRightBottomNeighbour;



@interface GSGCell : NSObject

@property (nonatomic, readonly) CGRect boundingBox;
@property (nonatomic, readonly) CGPoint centerPoint;
@property (nonatomic, readonly) CGPoint boundingBoxCenter;

@property (nonatomic, readonly) NSArray<GSGPoint *> *points;

@property (nonatomic, readonly) NSString *udid; // Unique cell identifier
@property (nonatomic) NSString *name;
@property (nonatomic) NSInteger tag;



- (id)initAtPoint:(CGPoint)point;

- (void)initialiseShape:(int)shapeIndex aroundPoint:(CGPoint)p;
- (NSArray<NSValue *> *)geometryData;
- (void)setGeometryData:(NSArray<NSValue *> *)geometry;

- (void)updateBezierControlVectors;
- (UIBezierPath *)bezierPath;
- (UIBezierPath *)bezierPathRelativeToPoint:(CGPoint)point closed:(BOOL)closed;
+ (UIBezierPath *)bezierPathFromPoints:(NSArray<GSGPoint *> *)points relativeToPoint:(CGPoint)point closed:(BOOL)closed;

- (BOOL)hasConnections;
- (BOOL)isConnectedOnLeftSide;
- (BOOL)isConnectedOnRightSide;
- (BOOL)hasAvailableConnections;

+ (NSInteger)indexOfNotConnectableNeighbour:(NSInteger)connectablePointIndex;
+ (NSInteger)indexOfConnectablePointToPoint:(NSInteger)pointIndex;
+ (NSInteger)indexOfOppositeSidePoint:(NSInteger)pointIndex;
+ (BOOL)isTopConnectablePoint:(NSInteger)pointIndex;

- (NSInteger)bezierSegmentIndexBetweenPoint1:(NSInteger)point1Index andPoint2:(NSInteger)point2Index;

- (BOOL)intersectsWithCell:(GSGCell *)cell;
- (BOOL)isConnectedToCell:(GSGCell *)cell;

- (void)moveBy:(CGPoint)moveVector;

@end
