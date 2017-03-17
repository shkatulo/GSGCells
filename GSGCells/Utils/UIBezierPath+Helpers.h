//
//  UIBezierPath+Helpers.h
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/16/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface UIBezierPath (Helpers)

- (NSInteger)elementCount;
- (CGPathElement)elementAtIndex:(NSInteger)askingForIndex associatedPoints:(CGPoint[])points;
- (void)fillBezier:(CGPoint[4])bezier forElement:(NSInteger)elementIndex;

+ (CGPoint)pointAtT:(CGFloat)t forBezier:(CGPoint*)bez;

+ (CGPathElement)copyCGPathElement:(CGPathElement *)element;
+ (void)destroyCGPathElement:(CGPathElement)element;

@end
