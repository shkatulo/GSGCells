//
//  GSGLellDebugLayer.m
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/10/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import "GSGDebugLayer.h"
#import "GeometryHelpers.h"



@implementation GSGDebugLayer

- (id)init {
    self = [super init];
    if (self) {
        self.contentsScale = [UIScreen mainScreen].scale;
    }
    return self;
}



- (void)drawInContext:(CGContextRef)context {
    [super drawInContext:context];
    
    UIGraphicsPushContext(context);
    
    [self drawControlPoints];
    [self drawCellName];
    
    UIGraphicsPopContext();
}



- (void)drawControlPoints {
    // Center point to calculate points lables positions
    CGPoint centerPoint = CGPointMake(self.bounds.size.width * 0.5f, self.bounds.size.height * 0.5f);
    
    // Attributes of point labels
    UIFont *pointLabelFont = [UIFont systemFontOfSize:12];
    NSDictionary *pointLabelAttributes = @{ NSFontAttributeName: pointLabelFont };
    
    for (int i = 0; i < _parentCellView.cell.points.count; ++i) {
        GSGPoint *point = _parentCellView.cell.points[i];
        
        if (point.isConnected) [[UIColor greenColor] setFill];
        else [[UIColor redColor] setFill];
        
        // Draw point circles
        CGPoint pos = [point positionRelativeToPoint:_parentCellView.cell.boundingBox.origin];
        [self drawCircleAtPoint:pos withRadius:4.0f];
        
        // Draw point numbers
        NSString *labelText = [@(i) stringValue];
        
        CGPoint offsetVector = CGPointSubtract(centerPoint, pos);
        offsetVector = CGPointNormalize(offsetVector);
        CGPoint labelPos = CGPointAdd(pos, CGPointScale(offsetVector, 20.0f));
        
        CGSize textSize = [labelText sizeWithAttributes:pointLabelAttributes];
        labelPos.x -= textSize.width * 0.5f;
        labelPos.y -= textSize.height * 0.5f;
        
        [labelText drawAtPoint:labelPos withAttributes:pointLabelAttributes];
    }
}



- (void)drawCellName {
    // Center point
    CGPoint centerPoint = CGPointMake(self.bounds.size.width * 0.5f, self.bounds.size.height * 0.5f);
    
    // Attributes of name text
    UIFont *pointLabelFont = [UIFont systemFontOfSize:15];
    NSDictionary *pointLabelAttributes = @{ NSFontAttributeName: pointLabelFont };
    
    // Draw text
    CGSize textSize = [_parentCellView.cell.name sizeWithAttributes:pointLabelAttributes];
    CGPoint labelPos = CGPointMake(centerPoint.x - textSize.width * 0.5f, centerPoint.y - textSize.height * 0.5f);
    
    [_parentCellView.cell.name drawAtPoint:labelPos withAttributes:pointLabelAttributes];
}



- (void)drawCircleAtPoint:(CGPoint)point withRadius:(float)radius {
    CGRect rect = CGRectMake(point.x - radius, point.y - radius, radius * 2, radius * 2);
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithOvalInRect:rect];
    [circlePath fill];
}



- (void)display {
    if (!_redrawAnimated) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
    }
    
    [super display];
    
    if (!_redrawAnimated) {
        [CATransaction commit];
    }
}

@end
