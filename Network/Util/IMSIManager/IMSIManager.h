//
//  IMSIManager.h
//  Network
//
//  Created by zhouqiang on 14/12/2017.
//

#import <Foundation/Foundation.h>
#import "IMSIXMLParser.h"

@interface IMSIManager : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (BOOL)update:(NSError **)error;

+ (IMSI *)infoForMCC:(NSString *)MCC MNC:(NSString *)MNC;

@property (class,nonatomic,strong,readonly) NSArray<IMSI *> *allPMLNs;

@end
