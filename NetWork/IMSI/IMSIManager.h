//
//  IMSIManager.h
//  NetWork
//
//  Created by zhouqiang on 02/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMSIXMLParser.h"

@interface IMSIManager : NSObject

@property (class,nonatomic,strong,readonly) NSArray<IMSI *> *allPMLNs;

+ (BOOL)update:(NSError **)error;

+ (IMSI *)infoForMCC:(NSString *)MCC MNC:(NSString *)MNC;

@end
