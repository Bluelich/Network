//
//  IMSIXMLParser.h
//  Network
//
//  Created by zhouqiang on 14/12/2017.
//

#import <Foundation/Foundation.h>
#import "IMSI.h"

@interface IMSIXMLParser : NSXMLParser

@property (nonatomic,strong,readonly) NSArray<IMSI *> *results;

@end
