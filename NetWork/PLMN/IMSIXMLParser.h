//
//  IMSIXMLParser.h
//  NetWork
//
//  Created by zhouqiang on 02/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PLMN;
@interface IMSIXMLParser : NSXMLParser

@property (nonatomic,strong,readonly) NSMutableArray<NSDictionary *> *results;

@property (nonatomic,strong,readonly) NSArray<PLMN *> *allIMSI;

@end
