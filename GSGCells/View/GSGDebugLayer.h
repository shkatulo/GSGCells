//
//  GSGLellDebugLayer.h
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/10/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GSGCellView.h"



@interface GSGDebugLayer : CALayer

@property (nonatomic) BOOL redrawAnimated;
@property (nonatomic, weak) GSGCellView *parentCellView;

@end
