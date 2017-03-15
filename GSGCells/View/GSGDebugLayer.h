//
//  GSGLellDebugLayer.h
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/10/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import <UIKit/UIKit.h>



@class GSGDebugLayer;



@protocol GSGDebugLayerDelegate <NSObject>

@optional

- (void)debugLayer:(GSGDebugLayer *)layer shouldBeDrawnInContext:(CGContextRef)context;

@end



@interface GSGDebugLayer : CALayer

@property (nonatomic) BOOL redrawAnimated;

@property (nonatomic, weak) id<GSGDebugLayerDelegate> drawingDelegate;

@end
