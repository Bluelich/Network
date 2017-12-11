//
//  WiFi.h
//  NetWork
//
//  Created by zhouqiang on 11/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WiFi : NSObject

/**
 WiFi Name
 */
@property (nonatomic,  copy,readonly) NSString  *SSID;
/**
 MAC Address
 */
@property (nonatomic,  copy,readonly) NSString  *BSSID;
/**
 Data of SSID
 */
@property (nonatomic,  copy,readonly) NSData    *SSIDData;

- (instancetype)initWithSSID:(NSString *)SSID
                       BSSID:(NSString *)BSSID
                    SSIDData:(NSData   *)SSIDData;

@end
