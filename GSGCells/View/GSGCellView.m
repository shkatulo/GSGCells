//
//  GSGCellView.m
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/10/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import "GSGCellView.h"
#import "GSGDebugLayer.h"
#import "GeometryHelpers.h"



@interface GSGCellView () <GSGDebugLayerDelegate>

@property (nonatomic, readonly) CAShapeLayer *shapeLayer;

@end



@implementation GSGCellView {
    GSGDebugLayer *_debugLayer;
    
    NSTimeInterval _shapeChangeDuration;
    NSArray<NSValue *> *_oldGeometry;
    CGRect _oldBoundingBox;
    
    BOOL _isTouched;
    BOOL _isDragging;
    CGPoint _dragOffset;
    CGPoint _originBeforeDrag;
}



- (id)init {
    self = [super init];
    if (self) {
        _isDraggable = YES;
        _dragThreshold = 3.0f;
        
        self.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.05f];
        
        self.shapeLayer.strokeColor = [UIColor redColor].CGColor;
        self.shapeLayer.lineWidth = 2.0f;
        self.shapeLayer.fillColor = [[UIColor blueColor] colorWithAlphaComponent:0.1f].CGColor;
        
        _debugLayer = [[GSGDebugLayer alloc] init];
        _debugLayer.drawingDelegate = self;
        [self.layer addSublayer:_debugLayer];
    }
    return self;
}



- (id)initWithCell:(GSGCell *)cell {
    self = [self init];
    if (self) {
        self.cell = cell;
    }
    return self;
}



+ (Class)layerClass {
    return [CAShapeLayer class];
}



#pragma mark -
#pragma mark Layout
- (void)layoutSubviews {
    [super layoutSubviews];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    _debugLayer.frame = self.bounds;
    [_debugLayer setNeedsDisplay];
    
    [CATransaction commit];
}



#pragma mark -
#pragma mark Updating data
- (void)setCell:(GSGCell *)cell {
    _cell = cell;
    
    [self updateFrame];
    [self updatePath];
}



#pragma mark -
#pragma mark Helpers
- (CAShapeLayer *)shapeLayer {
    return (CAShapeLayer *)self.layer;
}



- (void)updateFrame {
    CGRect boundingBox = _cell.boundingBox;
    self.frame = boundingBox;
}



- (void)updatePath {
    self.shapeLayer.path = [_cell bezierPathRelativeToPoint:self.frame.origin].CGPath;
}



#pragma mark -
#pragma mark Drawing debug info
- (void)debugLayer:(GSGDebugLayer *)layer shouldBeDrawnInContext:(CGContextRef)context {
    [self drawControlPointsInContext:context];
    [self drawCellNameInContext:context];
}



- (void)drawControlPointsInContext:(CGContextRef)context {
    CGContextSetTextDrawingMode(context, kCGTextFill);
    
    // Center point to calculate points lables positions
    CGPoint centerPoint = CGPointMake(self.bounds.size.width * 0.5f, self.bounds.size.height * 0.5f);
    
    // Attributes of point labels
    UIFont *pointLabelFont = [UIFont systemFontOfSize:12];
    NSDictionary *pointLabelAttributes = @{ NSFontAttributeName: pointLabelFont };
    
    for (int i = 0; i < _cell.points.count; ++i) {
        GSGPoint *point = _cell.points[i];
        
        if (point.isConnected) CGContextSetFillColorWithColor(context, [UIColor greenColor].CGColor);
        else CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
        
        // Draw point circles
        CGPoint pos = [point positionRelativeToPoint:_cell.boundingBox.origin];
        [self drawCircleAtPoint:pos withRadius:4.0f inContext:context];
        
        // Draw point numbers
        NSString *labelText = [@(i) stringValue];
        
        CGPoint offsetVector = CGPointSubtract(centerPoint, pos);
        offsetVector = CGPointNormalize(offsetVector);
        CGPoint labelPos = CGPointAdd(pos, CGPointScale(offsetVector, 20.0f));
        
        CGSize textSize = [labelText sizeWithAttributes:pointLabelAttributes];
        labelPos.x -= textSize.width * 0.5f;
        labelPos.y -= textSize.height * 0.5f;
        
        CGContextSaveGState(context);
        UIGraphicsPushContext(context);
        
        [labelText drawAtPoint:labelPos withAttributes:pointLabelAttributes];
        
        UIGraphicsPopContext();
        CGContextRestoreGState(context);
    }
}



- (void)drawCellNameInContext:(CGContextRef)context {
    // Center point
    CGPoint centerPoint = CGPointMake(self.bounds.size.width * 0.5f, self.bounds.size.height * 0.5f);
    
    // Attributes of name text
    UIFont *pointLabelFont = [UIFont systemFontOfSize:15];
    NSDictionary *pointLabelAttributes = @{ NSFontAttributeName: pointLabelFont };
    
    // Draw text
    CGSize textSize = [_cell.name sizeWithAttributes:pointLabelAttributes];
    CGPoint labelPos = CGPointMake(centerPoint.x - textSize.width * 0.5f, centerPoint.y - textSize.height * 0.5f);
    
    CGContextSaveGState(context);
    UIGraphicsPushContext(context);
    
    [_cell.name drawAtPoint:labelPos withAttributes:pointLabelAttributes];
    
    UIGraphicsPopContext();
    CGContextRestoreGState(context);
}



- (void)drawCircleAtPoint:(CGPoint)point withRadius:(float)radius inContext:(CGContextRef)context {
    CGContextBeginPath(context);
    CGContextAddArc(context, point.x, point.y, radius, 0, M_PI * 2, 1);
    CGContextFillPath(context);
}



- (void)setDebugLayerIsHidden:(BOOL)debugLayerIsHidden {
    _debugLayerIsHidden = debugLayerIsHidden;
    _debugLayer.hidden = _debugLayerIsHidden;
}



- (void)setNeedsDisplay {
    [super setNeedsDisplay];
    [_debugLayer setNeedsDisplay];
}



#pragma mark -
#pragma mark ShapeChange
- (void)beginShapeChangeWithDuration:(NSTimeInterval)duration {
    _shapeChangeDuration = duration;
    
    // Store old state
    if (_shapeChangeDuration != 0) {
        _oldGeometry = _cell.geometryData;
        _oldBoundingBox = _cell.boundingBox;
    }
}



- (void)endShapeChange {
    if (_shapeChangeDuration != 0) {
        // Hide debug layer
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        _debugLayer.hidden = YES;
        [CATransaction commit];
        
        // Calculate bounding box which contain old and new states
        NSArray<NSValue *> *newGeometry = _cell.geometryData;
        CGRect newBoundingBox = _cell.boundingBox;
        
        CGRect animationRect = CGRectUnion(_oldBoundingBox, newBoundingBox);
        self.frame = animationRect;
        
        // Restore old state in full animation area
        [_cell setGeometryData:_oldGeometry];
        [self updatePath];
        
        // Restore new state in full animation area
        [_cell setGeometryData:newGeometry];
        
        // Animate path
        CGPathRef newPath = [_cell bezierPathRelativeToPoint:self.frame.origin].CGPath;
        
        [CATransaction begin];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
        animation.fromValue = (__bridge id _Nullable)(self.shapeLayer.path);
        animation.toValue = (__bridge id _Nullable)(newPath);
        animation.duration = _shapeChangeDuration;
        [CATransaction setCompletionBlock:^{
            // Restore frame
            [self updateFrame];
            [self updatePath];
            
            // Show debug layer
            [_debugLayer setNeedsDisplay];
            _debugLayer.hidden = _debugLayerIsHidden;
        }];
        [self.shapeLayer addAnimation:animation forKey:animation.keyPath];
        [CATransaction commit];
        
        self.shapeLayer.path = newPath;
        
    }
    else {
        [self updateFrame];
        [self updatePath];
    }
    
    _oldGeometry = nil;
}



#pragma mark -
#pragma mark Dragging
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // Check if touch is inside cell path
    if (CGPathContainsPoint(self.shapeLayer.path, nil, point, YES))
        return self;
    
    return nil;
}



- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_isTouched)
        return;
    
    UITouch *touch = [touches anyObject];
    _dragOffset = [touch locationInView:self];
    
    _originBeforeDrag = self.frame.origin;
    _isTouched = YES;
    _isDragging = NO;
}



- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!_isTouched)
        return;
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.superview];
    
    CGPoint newOrigin = CGPointMake(location.x - _dragOffset.x, location.y - _dragOffset.y);
    
    if (_isDragging) {
        [self dragWithNewOrigin:newOrigin];
    }
    else {
        float dragDistance = CGPointGetDistance(_originBeforeDrag, newOrigin);
        
        if (dragDistance > _dragThreshold) {
            if (_isDraggable) {
                _isDragging = YES;
                
                // Dragging begin callback
                if ([self.delegate respondsToSelector:@selector(cellViewDidStartDragging:)]) {
                    [self.delegate cellViewDidStartDragging:self];
                }
                
                // Handle first move
                [self dragWithNewOrigin:newOrigin];
            }
            else {
                _isTouched = NO;
            }
        }
    }
}



- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!_isTouched)
        return;
    
    if (_isDragging) {
        // Update model
        CGPoint dragVector = CGPointSubtract(self.frame.origin, _originBeforeDrag);
        [_cell moveBy:dragVector];
        [_cell updateBezierControlVectors];
        
        // End dragging callback
        if ([self.delegate respondsToSelector:@selector(cellViewDidFinishDragging:)]) {
            [self.delegate cellViewDidFinishDragging:self];
        }
    }
    else {
        // Tapped callback
        if ([self.delegate respondsToSelector:@selector(cellViewDidTap:)]) {
            [self.delegate cellViewDidTap:self];
        }
    }
    
    _isTouched = NO;
    _isDragging = NO;
}



- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}



- (void)dragWithNewOrigin:(CGPoint)newOrigin {
    self.frame = CGRectMake(newOrigin.x, newOrigin.y, self.frame.size.width, self.frame.size.height);
    
    // Move callback
    if ([self.delegate respondsToSelector:@selector(cellViewDidDrag:)]) {
        [self.delegate cellViewDidDrag:self];
    }
}

@end
