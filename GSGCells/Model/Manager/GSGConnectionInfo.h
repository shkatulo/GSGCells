//
//  GSGConnectionInfo.h
//  GSGCells
//
//  Created by Serhii Shkatulo on 3/13/17.
//  Copyright © 2017 GSG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GSGCell.h"



@interface GSGConnectionInfo : NSObject

@property (nonatomic) GSGCell *cellFrom;
@property (nonatomic) GSGCell *cellTo;

@property (nonatomic) NSInteger fromTopPointIndex;
@property (nonatomic) NSInteger toTopPointIndex;

@property (nonatomic) NSInteger fromBottomPointIndex;
@property (nonatomic) NSInteger toBottomPointIndex;

@end
