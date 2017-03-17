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



#define SHAPES_COUNT 2



@interface ViewController () <GSGCellViewDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *swtAnimated;
@property (weak, nonatomic) IBOutlet UIButton *btnConnect;
@property (weak, nonatomic) IBOutlet UIButton *btnAddCell;

@end



@implementation ViewController {
    GSGCellsManager *_cellsManager;
    NSMutableArray<GSGCellView *> *_cellViews;
    
    NSMutableArray<GSGCellView *> *_operationAffectedViews;
    
    int _shapeIndex;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    _cellViews = [NSMutableArray array];
    _cellsManager = [[GSGCellsManager alloc] init];
    _operationAffectedViews = [NSMutableArray array];
    
    [self addNewCell];
    
    [self updateConnectButtonVisibility];
}




- (IBAction)actionChangeShape:(id)sender {
    GSGCellView *cellView = [self latestCellView];
    if ([cellView.cell hasConnections])
        return;
    
    _shapeIndex = (_shapeIndex + 1) % SHAPES_COUNT;
    
    [cellView beginShapeChangeWithDuration:self.swtAnimated.on ? 0.5 : 0.0];
    [cellView.cell initialiseShape:_shapeIndex aroundPoint:cellView.cell.centerPoint];
    [cellView endShapeChange];
    
    [self updateConnectButtonVisibility];
}



- (IBAction)actionConnect:(id)sender {
    NSMutableArray<GSGConnectionInfo *> *connections = [[_cellsManager getAvailableConnections] mutableCopy];
    
    [self beginCellsOperations];
    [self applyConnections:connections];
    [self endCellsOperations];
    
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



- (void)beginCellsOperations {
    [_operationAffectedViews removeAllObjects];
}



- (void)addOperationAffectedCell:(GSGCell *)cell {
    GSGCellView *cellView = [self cellViewForCell:cell];
    
    if (![_operationAffectedViews containsObject:cellView]) {
        [_operationAffectedViews addObject:cellView];
        [cellView beginShapeChangeWithDuration:self.swtAnimated.on ? 0.5 : 0.0];
    }
}



- (void)endCellsOperations {
    // End animation for affected cell views
    for (GSGCellView *cellView in _operationAffectedViews) {
        [cellView endShapeChange];
        cellView.isDraggable = NO;
    }
    
    [_operationAffectedViews removeAllObjects];
}



- (void)applyConnections:(NSArray<GSGConnectionInfo *> *)connections {
    // Apply available connections
    for (GSGConnectionInfo *connection in connections) {
        [self addOperationAffectedCell:connection.cellFrom];
        [self addOperationAffectedCell:connection.cellTo];
        
        // Do connection logic
        [_cellsManager connectCells:connection];
    }
}



- (void)applyInsertions:(NSArray<GSGInsertionInfo *> *)insertions {
    // Apply available insertions
    for (GSGInsertionInfo *insertion in insertions) {
        [self addOperationAffectedCell:insertion.insertingCell];
        [self addOperationAffectedCell:insertion.cellA];
        [self addOperationAffectedCell:insertion.cellB];
        
        // Do insertion logic
        [_cellsManager insertCell:insertion];
    }
}



#pragma mark -
#pragma mark Cell view delegate
- (void)cellViewDidFinishDragging:(GSGCellView *)cellView {
    // Check insertions
    NSArray<GSGInsertionInfo *> *insertions = [_cellsManager getAvailableInsertions];
//    NSLog(@"Available insertions: %lu", (unsigned long)insertions.count);
    
    [self beginCellsOperations];
    [self applyInsertions:insertions];
    [self endCellsOperations];
    
    
    // Check connections
    [self updateConnectButtonVisibility];
}



- (void)cellViewDidTap:(GSGCellView *)cellView {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cell tapped"
                                                                   message:cellView.cell.name
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
