//
//  IMSIManager.h
//  NetWork
//
//  Created by zhouqiang on 02/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PLMN;

@interface IMSIManager : NSObject

@property (class,nonatomic,strong,readonly) NSArray<PLMN *> *allPMLNs;

+ (BOOL)update:(NSError **)error;

@end
