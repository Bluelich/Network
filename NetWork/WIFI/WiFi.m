//
//  WiFi.m
//  NetWork
//
//  Created by zhouqiang on 11/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
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
