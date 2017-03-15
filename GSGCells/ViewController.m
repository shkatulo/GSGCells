//
//  ViewController.m
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/10/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import "ViewController.h"
#import "GSGCellView.h"
#import "GSGCellsManager.h"
#import "GeometryHelpers.h"
#import <ClippingBezier/ClippingBezier.h>
#import <PerformanceBezier/PerformanceBezier.h>



#define SHAPES_COUNT 2



@interface ViewController () <GSGCellViewDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *swtAnimated;
@property (weak, nonatomic) IBOutlet UIButton *btnConnect;
@property (weak, nonatomic) IBOutlet UIButton *btnAddCell;

@end



@implementation ViewController {
    GSGCellsManager *_cellsManager;
    NSMutableArray<GSGCellView *> *_cellViews;
    
    int _shapeIndex;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    _cellViews = [NSMutableArray array];
    _cellsManager = [[GSGCellsManager alloc] init];
    
    [self addNewCell];
    
    [self updateConnectButtonVisibility];
}




- (IBAction)actionChangeShape:(id)sender {
    _shapeIndex = (_shapeIndex + 1) % SHAPES_COUNT;
    
    GSGCellView *cellView = [self latestCellView];
    [cellView beginShapeChangeWithDuration:self.swtAnimated.on ? 0.5 : 0.0];
    [cellView.cell initialiseShape:_shapeIndex aroundPoint:cellView.cell.centerPoint];
    [cellView endShapeChange];
    
    [self updateConnectButtonVisibility];
}



- (IBAction)actionConnect:(id)sender {
    NSArray<GSGConnectionInfo *> *connections = [_cellsManager getAvailableConnections];
    NSMutableArray<GSGCellView *> *affectedViews = [NSMutableArray array];
 
    // Apply available connections
    for (GSGConnectionInfo *connection in connections) {
        // Get presentation views for connected cells
        GSGCellView *cellViewFrom = [self cellViewForCell:connection.cellFrom];
        GSGCellView *cellViewTo = [self cellViewForCell:connection.cellTo];
        
        // Begin animated shape change of both connected cells
        if (![affectedViews containsObject:cellViewFrom]) {
            [affectedViews addObject:cellViewFrom];
            [cellViewFrom beginShapeChangeWithDuration:self.swtAnimated.on ? 0.5 : 0.0];
        }
        
        if (![affectedViews containsObject:cellViewTo]) {
            [affectedViews addObject:cellViewTo];
            [cellViewTo beginShapeChangeWithDuration:self.swtAnimated.on ? 0.5 : 0.0];
        }
        
        // Do connection logic
        [_cellsManager connectCells:connection];
    }
    
    // End animation for affected cell views
    for (GSGCellView *cellView in affectedViews) {
        [cellView endShapeChange];
        cellView.isDraggable = NO;
    }
    
    [self updateConnectButtonVisibility];
}



- (IBAction)actionAddCell:(id)sender {
    [self addNewCell];
}



- (GSGCellView *)latestCellView {
    return _cellViews.lastObject;
}



- (GSGCellView *)cellViewForCell:(GSGCell *)cell {
    for (GSGCellView *cellView in _cellViews) {
        if (cellView.cell == cell) {
            return cellView;
        }
    }
    
    return nil;
}



- (void)addNewCell {
    // Create cell model
    CGPoint position = CGPointMultiply(self.view.center, CGPointMake(1.0f, 1.5f));
    GSGCell *cell = [[GSGCell alloc] initAtPoint:position];
    cell.name = [NSString stringWithFormat:@"#%lu", _cellViews.count + 1];
    [_cellsManager addCell:cell];
    
    // Create cell view
    GSGCellView *cellView = [[GSGCellView alloc] initWithCell:cell];
//    cellView.debugLayerIsHidden = YES;
    cellView.delegate = self;
    [self.view addSubview:cellView];
    [_cellViews addObject:cellView];
    
    _shapeIndex = 0;
}



- (void)updateConnectButtonVisibility {
    NSArray *connections = [_cellsManager getAvailableConnections];
    self.btnConnect.hidden = (connections.count == 0);
}



#pragma mark -
#pragma mark Cell view delegate
- (void)cellViewDidFinishDragging:(GSGCellView *)cellView {
    [self updateConnectButtonVisibility];
    
    // Testing cells intersection
    if (_cellViews.count == 2) {
        GSGCellView *cellView1 = _cellViews[0];
        GSGCellView *cellView2 = _cellViews[1];
        
        BOOL intersects = [cellView1.cell intersectsWithCell:cellView2.cell];
        NSLog(@"Cells intersection: %@", intersects ? @"YES" : @"NO");
    }
}



- (void)cellViewDidTap:(GSGCellView *)cellView {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cell tapped"
                                                                   message:cellView.cell.name
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
