//
//  DKUIBezierPathShape.m
//  ClippingBezier
//
//  Created by Adam Wulf on 11/18/13.
//  Copyright (c) 2013 Adam Wulf. All rights reserved.
//

#import "DKUIBezierPathShape.h"
#import "DKUIBezierPathClippedSegment.h"
#import <PerformanceBezier/PerformanceBezier.h>
#import "UIBezierPath+Trimming.h"

@implementation DKUIBezierPathShape

@synthesize segments;
@synthesize holes;

-(id) init{
    if(self = [super init]){
        segments = [NSMutableArray array];
        holes = [NSMutableArray array];
    }
    return self;
}


-(DKUIBezierPathIntersectionPoint*) startingPoint{
    return [[segments firstObject] startIntersection];
}

-(DKUIBezierPathIntersectionPoint*) endingPoint{
    return [[segments lastObject] endIntersection];
}

-(BOOL) isClosed{
    return [[self startingPoint] matchesElementEndpointWithIntersection:[self endingPoint]];
}

-(UIBezierPath*) fullPath{
    UIBezierPath* outputPath = [[[segments firstObject] pathSegment] copy];
    for(int i=1;i<[segments count];i++){
        DKUIBezierPathClippedSegment* seg = [segments objectAtIndex:i];
        [outputPath appendPathRemovingInitialMoveToPoint:[seg pathSegment]];
    }
    if([self isClosed]){
        [outputPath closePath];
    }else{
        NSLog(@"unclosed shape??");
    }
    BOOL selfIsClockwise = [outputPath isClockwise];
    for(DKUIBezierPathShape* hole in holes){
        UIBezierPath* holePath = hole.fullPath;
        if([holePath isClockwise] == selfIsClockwise){
            holePath = [holePath bezierPathByReversingPath];
        }
        [outputPath appendPath:holePath];
    }
    return outputPath;
}

-(BOOL) isSameShapeAs:(DKUIBezierPathShape*)otherShape{
    if([self.holes count] != [otherShape.holes count]){
        // shortcut. if we don't have the same number of segments,
        // then we're not the same shape
        return NO;
    }
    if([self.segments count] != [otherShape.segments count]){
        // shortcut. if we don't have the same number of segments,
        // then we're not the same shape
        return NO;
    }
    __block BOOL foundAllSegments = YES;
    [self.segments enumerateObjectsUsingBlock:^(id obj1, NSUInteger idx, BOOL* stop){
        if([self.segments count] == 1 && [otherShape.segments count] == 1){
            // special case if the shape is a single red segment
            // and we're comparing to our reversed single red segment
            if([[self.segments firstObject] isEqualToSegment:[otherShape.segments firstObject]] ||
               [[[self.segments firstObject] reversedSegment] isEqualToSegment:[otherShape.segments firstObject]]){
                foundAllSegments = YES;
                stop[0] = YES;
                return;
            }
        }
        __block BOOL foundSegment = NO;
        [otherShape.segments enumerateObjectsUsingBlock:^(id obj2, NSUInteger idx, BOOL* stop){
            if([obj1 isEqualToSegment:obj2]){
                foundSegment = YES;
                stop[0] = YES;
            }
        }];
        if(!foundSegment){
            foundAllSegments = NO;
            stop[0] = YES;
        }
    }];
    __block BOOL foundAllShapes = YES;
    [self.holes enumerateObjectsUsingBlock:^(id obj1, NSUInteger idx, BOOL* stop){
        __block BOOL foundHole = NO;
        [otherShape.holes enumerateObjectsUsingBlock:^(id obj2, NSUInteger idx, BOOL* stop){
            if([obj1 isSameShapeAs:obj2]){
                foundHole = YES;
                stop[0] = YES;
            }
        }];
        if(!foundHole){
            foundAllShapes = NO;
            stop[0] = YES;
        }
    }];
    
    return foundAllSegments && foundAllShapes;
}

-(BOOL) sharesSegmentWith:(DKUIBezierPathShape*)otherShape{
    for (DKUIBezierPathClippedSegment* otherSegment in otherShape.segments){
        if([self.segments containsObject:otherSegment]){
            return YES;
        }
    }
    return NO;
}


@end
