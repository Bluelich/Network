//
//  IMSI.m
//  Network
//
//  Created by zhouqiang on 14/12/2017.
//

#import "IMSI.h"

@interface IMSI ()
@property (nonatomic, copy) NSString  *MCC;
@property (nonatomic, copy) NSString  *MNC;
@property (nonatomic, copy) NSString  *ISO;
@property (nonatomic, copy) NSString  *country;
@property (nullable, nonatomic, copy) NSString  *countryCode;
@property (nullable, nonatomic, copy) NSString  *network;
@end

@implementation IMSI

- (instancetype)initWithMCC:(NSString *)MCC
                        MNC:(NSString *)MNC
                        ISO:(NSString *)ISO
                    country:(NSString *)country
                countryCode:(nullable NSString *)countryCode
                    network:(nullable NSString *)network
{
    self = [super init];
    if (self) {
        self.MCC = MCC;
        self.MNC = MNC;
        self.ISO = ISO;
        self.country = country;
        self.countryCode = countryCode;
        self.network = network;
    }
    return self;
}
- (NSString *)description
{
    return [NSString stringWithFormat:@"{\n\tMCC:%@\n\tMNC:%@\n\tISO:%@\n\tcountry:%@\n\tcountry Code:%@\n\tnetwork:%@\n}",self.MCC,self.MNC,self.ISO,self.country,self.countryCode,self.network];
}
@end

