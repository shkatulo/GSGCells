//
//  GSGCellsManager.h
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/13/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GSGInsertionInfo.h"



@interface GSGCellsManager : NSObject

@property (nonatomic, readonly) NSArray<GSGCell *> *cells;

@property (nonatomic) float connectionDistance;
@property (nonatomic) float connectionDetectionDistance;
@property (nonatomic) float minInsertionDistance;


- (void)addCell:(GSGCell *)cell;
- (void)removeCell:(GSGCell *)cell;

- (NSArray<GSGConnectionInfo *> *)getAvailableConnections;
- (NSArray<GSGInsertionInfo *> *)getAvailableInsertions;

- (void)connectCells:(GSGConnectionInfo *)connectionInfo;
- (void)insertCell:(GSGInsertionInfo *)insertionInfo;
- (void)disconnectCell:(GSGCell *)cell;

@end
