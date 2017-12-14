//
//  WiFi.h
//  Network
//
//  Created by zhouqiang on 14/12/2017.
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
