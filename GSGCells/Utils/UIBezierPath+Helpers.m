//
//  UIBezierPath+Helpers.m
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/16/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import "UIBezierPath+Helpers.h"



@implementation UIBezierPath (Helpers)

- (NSInteger)elementCount {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:[NSNumber numberWithInteger:0] forKey:@"count"];
    
    CGPathApply(self.CGPath, (__bridge void * _Nullable)(params), countPathElement);
    
    NSInteger ret = [[params objectForKey:@"count"] integerValue];
    return ret;
}

void countPathElement(void *info, const CGPathElement *element) {
    NSMutableDictionary *params = (__bridge NSMutableDictionary *)(info);
    NSInteger count = [params[@"count"] integerValue];
    
    params[@"count"] = @(count + 1);
}



- (CGPathElement)elementAtIndex:(NSInteger)askingForIndex associatedPoints:(CGPoint[])points {
    __block BOOL didReturn = NO;
    __block CGPathElement returnVal;
    
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger currentIndex){
        if (didReturn)
            return;
        
        if (currentIndex == askingForIndex){
            returnVal = [UIBezierPath copyCGPathElement:&element];
            didReturn = YES;
        }
    }];
    
    if (points) {
        for (int i = 0; i < [UIBezierPath numberOfPointsForElement:returnVal]; i++){
            points[i] = returnVal.points[i];
        }
    }
    return returnVal;
}



- (void)iteratePathWithBlock:(void (^)(CGPathElement element, NSUInteger idx))block {
    NSMutableDictionary* params = [@{ @"block" : block } mutableCopy];
    CGPathApply(self.CGPath, (__bridge void * _Nullable)(params), blockWithElement);
}

static void blockWithElement(void* info, const CGPathElement* element) {
    NSMutableDictionary* params = (__bridge NSMutableDictionary *)(info);
    void (^block)(CGPathElement element,NSUInteger idx) = params[@"block"];
    
    NSUInteger index = [[params objectForKey:@"index"] unsignedIntegerValue];
    block(*element, index);
    params[@"index"] = @(index+1);
}



+ (NSInteger)numberOfPointsForElement:(CGPathElement)element {
    NSInteger nPoints = 0;
    switch (element.type)
    {
        case kCGPathElementMoveToPoint:
            nPoints = 1;
            break;
        case kCGPathElementAddLineToPoint:
            nPoints = 1;
            break;
        case kCGPathElementAddQuadCurveToPoint:
            nPoints = 2;
            break;
        case kCGPathElementAddCurveToPoint:
            nPoints = 3;
            break;
        case kCGPathElementCloseSubpath:
            nPoints = 0;
            break;
        default:
            nPoints = 0;
    }
    
    return nPoints;
}



+ (CGPathElement)copyCGPathElement:(CGPathElement *)element {
    CGPathElement ret;
    
    NSInteger numberOfPoints = [UIBezierPath numberOfPointsForElement:*element];
    if(numberOfPoints) {
        ret.points = malloc(sizeof(CGPoint) * numberOfPoints);
    }
    else{
        ret.points = NULL;
    }
    ret.type = element->type;
    
    for (int i = 0; i < numberOfPoints; i++) {
        ret.points[i] = element->points[i];
    }
    return ret;
}



+ (void)destroyCGPathElement:(CGPathElement)element {
    if (element.points) free(element.points);
}



+ (CGPoint)pointAtT:(CGFloat)t forBezier:(CGPoint*)bez {
    CGPoint q;
    CGFloat mt = 1 - t;
    
    CGPoint bez1[4];
    CGPoint bez2[4];
    
    q.x = mt * bez[1].x + t * bez[2].x;
    q.y = mt * bez[1].y + t * bez[2].y;
    bez1[1].x = mt * bez[0].x + t * bez[1].x;
    bez1[1].y = mt * bez[0].y + t * bez[1].y;
    bez2[2].x = mt * bez[2].x + t * bez[3].x;
    bez2[2].y = mt * bez[2].y + t * bez[3].y;
    
    bez1[2].x = mt * bez1[1].x + t * q.x;
    bez1[2].y = mt * bez1[1].y + t * q.y;
    bez2[1].x = mt * q.x + t * bez2[2].x;
    bez2[1].y = mt * q.y + t * bez2[2].y;
    
    bez1[3].x = bez2[0].x = mt * bez1[2].x + t * bez2[1].x;
    bez1[3].y = bez2[0].y = mt * bez1[2].y + t * bez2[1].y;
    
    return CGPointMake(bez1[3].x, bez1[3].y);
}



- (void)fillBezier:(CGPoint[4])bezier forElement:(NSInteger)elementIndex {
    if(elementIndex >= [self elementCount] || elementIndex < 0){
        @throw [NSException exceptionWithName:@"BezierElementException" reason:@"Element index is out of range" userInfo:nil];
    }
    
    CGPoint firstPoint = [self firstPointCalculated];
    
    if(elementIndex == 0){
        bezier[0] = firstPoint;
        bezier[1] = firstPoint;
        bezier[2] = firstPoint;
        bezier[3] = firstPoint;
        return;
    }
    
    CGPathElement previousElement = [self elementAtIndex:elementIndex-1 associatedPoints:NULL];
    CGPathElement thisElement = [self elementAtIndex:elementIndex associatedPoints:NULL];
    
    if(previousElement.type == kCGPathElementMoveToPoint ||
       previousElement.type == kCGPathElementAddLineToPoint) {
        bezier[0] = previousElement.points[0];
    }
    else if(previousElement.type == kCGPathElementAddQuadCurveToPoint) {
        bezier[0] = previousElement.points[1];
    }
    else if(previousElement.type == kCGPathElementAddCurveToPoint) {
        bezier[0] = previousElement.points[2];
    }
    
    if (thisElement.type == kCGPathElementCloseSubpath){
        bezier[1] = bezier[0];
        bezier[2] = firstPoint;
        bezier[3] = firstPoint;
    }
    else if (thisElement.type == kCGPathElementMoveToPoint ||
             thisElement.type == kCGPathElementAddLineToPoint) {
        bezier[1] = bezier[0];
        bezier[2] = thisElement.points[0];
        bezier[3] = thisElement.points[0];
    }
    else if (thisElement.type == kCGPathElementAddQuadCurveToPoint) {
        bezier[1] = thisElement.points[0];
        bezier[2] = thisElement.points[0];
        bezier[3] = thisElement.points[1];
    }
    else if (thisElement.type == kCGPathElementAddCurveToPoint) {
        bezier[1] = thisElement.points[0];
        bezier[2] = thisElement.points[1];
        bezier[3] = thisElement.points[2];
    }
}



- (CGPoint)firstPointCalculated{
    __block CGPoint firstPoint = CGPointZero;
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger idx) {
        if(idx == 0) {
            if(element.type == kCGPathElementMoveToPoint ||
               element.type == kCGPathElementAddLineToPoint) {
                firstPoint = element.points[0];
            }
            else if(element.type == kCGPathElementCloseSubpath) {
                firstPoint = firstPoint;
            }
            else if(element.type == kCGPathElementAddCurveToPoint) {
                firstPoint = element.points[2];
            }
            else if(element.type == kCGPathElementAddQuadCurveToPoint) {
                firstPoint = element.points[1];
            }
        }
    }];
    
    return firstPoint;
}

@end
