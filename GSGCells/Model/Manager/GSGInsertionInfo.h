//
//  GSGInsertionInfo.h
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/13/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GSGConnectionInfo.h"



@interface GSGInsertionInfo : NSObject

- (id)initWithInsertingCell:(GSGCell *)insertingCell cellA:(GSGCell *)cellA cellB:(GSGCell *)cellB;


@property (nonatomic) GSGCell *insertingCell;
@property (nonatomic) GSGCell *cellA;
@property (nonatomic) GSGCell *cellB;

// Optional connections. Are set if insertion was built from 2 connections
@property (nonatomic) GSGConnectionInfo *connectionA;
@property (nonatomic) GSGConnectionInfo *connectionB;

@end
