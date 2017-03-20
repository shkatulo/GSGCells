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



@interface GSGCellView ()

@property (nonatomic, readonly) CAShapeLayer *shapeLayer;

@end



@implementation GSGCellView {
    GSGDebugLayer *_debugLayer;
    
    NSTimeInterval _shapeChangeDuration;
    NSArray<NSValue *> *_oldGeometry;
    CGRect _oldBoundingBox;
    
    CGPoint _dragOffset;
    CGPoint _originBeforeDrag;
}



- (id)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.05f];
        
        self.shapeLayer.strokeColor = [UIColor redColor].CGColor;
        self.shapeLayer.lineWidth = 2.0f;
        self.shapeLayer.fillColor = [[UIColor blueColor] colorWithAlphaComponent:0.1f].CGColor;
        
        _debugLayer = [[GSGDebugLayer alloc] init];
        _debugLayer.parentCellView = self;
        [self.layer addSublayer:_debugLayer];
        
        _dragGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(actionDragCell:)];
        [self addGestureRecognizer:_dragGestureRecognizer];
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
    self.shapeLayer.path = [_cell bezierPathRelativeToPoint:self.frame.origin closed:YES].CGPath;
}



#pragma mark -
#pragma mark Debug info
- (void)setNeedsDisplay {
    [super setNeedsDisplay];
    [_debugLayer setNeedsDisplay];
}



- (void)setDebugLayerIsHidden:(BOOL)debugLayerIsHidden {
    _debugLayerIsHidden = debugLayerIsHidden;
    _debugLayer.hidden = _debugLayerIsHidden;
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
        CGPathRef newPath = [_cell bezierPathRelativeToPoint:self.frame.origin closed:YES].CGPath;
        
        [CATransaction begin];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
        animation.fromValue = (__bridge id _Nullable)(self.shapeLayer.path);
        animation.toValue = (__bridge id _Nullable)(newPath);
        animation.duration = _shapeChangeDuration;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
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



- (void)actionDragCell:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        _dragOffset = [sender locationInView:self];
        _originBeforeDrag = self.frame.origin;
        
        // Dragging begin callback
        if ([self.delegate respondsToSelector:@selector(cellViewDidStartDragging:)]) {
            [self.delegate cellViewDidStartDragging:self];
        }
    }
    else if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint location = [sender locationInView:self.superview];
        CGPoint newOrigin = CGPointMake(location.x - _dragOffset.x, location.y - _dragOffset.y);
        
        self.frame = CGRectMake(newOrigin.x, newOrigin.y, self.frame.size.width, self.frame.size.height);
        
        // Move callback
        if ([self.delegate respondsToSelector:@selector(cellViewDidDrag:)]) {
            [self.delegate cellViewDidDrag:self];
        }
    }
    else if (sender.state == UIGestureRecognizerStateEnded) {
        // Update model
        CGPoint dragVector = CGPointSubtract(self.frame.origin, _originBeforeDrag);
        [_cell moveBy:dragVector];
        [_cell updateBezierControlVectors];
        
        // End dragging callback
        if ([self.delegate respondsToSelector:@selector(cellViewDidFinishDragging:)]) {
            [self.delegate cellViewDidFinishDragging:self];
        }
    }
}

@end
