//
//  IMSIXMLParser.h
//  NetWork
//
//  Created by zhouqiang on 02/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMSI.h"

@interface IMSIXMLParser : NSXMLParser

@property (nonatomic,strong,readonly) NSArray<IMSI *> *results;

@end
