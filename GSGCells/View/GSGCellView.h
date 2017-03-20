//
//  GSGCellView.h
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/10/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GSGCell.h"



@class GSGCellView;

@protocol GSGCellViewDelegate <NSObject>

@optional

- (void)cellViewDidStartDragging:(GSGCellView *)cellView;
- (void)cellViewDidDrag:(GSGCellView *)cellView;
- (void)cellViewDidFinishDragging:(GSGCellView *)cellView;

@end



@interface GSGCellView : UIView

@property (nonatomic) GSGCell *cell;
@property (nonatomic) BOOL debugLayerIsHidden;

@property (nonatomic, readonly) UIPanGestureRecognizer *dragGestureRecognizer;

@property (nonatomic, weak) id<GSGCellViewDelegate> delegate;


- (id)initWithCell:(GSGCell *)cell;

- (void)beginShapeChangeWithDuration:(NSTimeInterval)duration;
- (void)endShapeChange;

@end
