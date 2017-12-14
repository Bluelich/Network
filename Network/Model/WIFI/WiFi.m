//
//  WiFi.m
//  Network
//
//  Created by zhouqiang on 14/12/2017.
//

#import "WiFi.h"

@interface WiFi ()

@property (nonatomic,  copy) NSString  *SSID;
@property (nonatomic,  copy) NSString  *BSSID;
@property (nonatomic,  copy) NSData    *SSIDData;

@end

@implementation WiFi
- (instancetype)initWithSSID:(NSString *)SSID
                       BSSID:(NSString *)BSSID
                    SSIDData:(NSData   *)SSIDData
{
    self = [super init];
    if (self) {
        self.SSID = SSID;
        self.BSSID = BSSID;
        self.SSIDData = SSIDData;
    }
    return self;
}
@end

