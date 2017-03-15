//
//  GSGInsertionInfo.m
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/13/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import "GSGInsertionInfo.h"



@implementation GSGInsertionInfo

- (id)initWithInsertingCell:(GSGCell *)insertingCell cellA:(GSGCell *)cellA cellB:(GSGCell *)cellB {
    self = [super init];
    if (self) {
        _insertingCell = insertingCell;
        _cellA = cellA;
        _cellB = cellB;
    }
    return self;
}

@end
