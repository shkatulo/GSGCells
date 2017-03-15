//
//  GSGLellDebugLayer.m
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/10/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import "GSGDebugLayer.h"



@implementation GSGDebugLayer

- (id)init {
    self = [super init];
    if (self) {
        self.contentsScale = [UIScreen mainScreen].scale;
    }
    return self;
}



- (void)drawInContext:(CGContextRef)ctx {
    [super drawInContext:ctx];
    
    if ([self.drawingDelegate respondsToSelector:@selector(debugLayer:shouldBeDrawnInContext:)]) {
        [self.drawingDelegate debugLayer:self shouldBeDrawnInContext:ctx];
    }
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
