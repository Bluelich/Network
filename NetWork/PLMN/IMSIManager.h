//
//  IMSIManager.h
//  NetWork
//
//  Created by zhouqiang on 02/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLMN.h"

@interface IMSIManager : NSObject

@property (nonatomic,strong) NSMutableArray<PLMN *> *data;

+ (void)update;

- (NSArray<NSDictionary *> *)update;

@end
