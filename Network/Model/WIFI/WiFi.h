//
//  WiFi.h
//  Network
//
//  Created by zhouqiang on 14/12/2017.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_OSX

#import <CoreWLAN/CoreWLAN.h>

FOUNDATION_EXPORT NSString *NSStringFromCWErr(CWErr err);
FOUNDATION_EXPORT NSString *NSStringFromCWPHYMode(CWPHYMode mode);
FOUNDATION_EXPORT NSString *NSStringFromCWInterfaceMode(CWInterfaceMode mode);
FOUNDATION_EXPORT NSString *NSStringFromCWSecurity(CWSecurity mode);
FOUNDATION_EXPORT NSString *NSStringFromCWIBSSModeSecurity(CWIBSSModeSecurity mode);
FOUNDATION_EXPORT NSString *NSStringFromCWChannelWidth(CWChannelWidth mode);
FOUNDATION_EXPORT NSString *NSStringFromCWChannelBand(CWChannelBand mode);
FOUNDATION_EXPORT NSString *NSStringFromCWCipherKeyFlags(CWCipherKeyFlags flag);
FOUNDATION_EXPORT NSString *NSStringFromCWKeychainDomain(CWKeychainDomain mode);
FOUNDATION_EXPORT NSString *NSStringFromCWEventType(CWEventType mode);

FOUNDATION_EXPORT NSString *WiFiDescriptionForCWInterface(CWInterface *interface);
FOUNDATION_EXPORT NSString *WiFiDescriptionForCWNetwork(CWNetwork *network);
FOUNDATION_EXPORT NSString *WiFiDescriptionForCWChannel(CWChannel *channel);
FOUNDATION_EXPORT NSString *WiFiDescriptionForCWConfiguration(CWConfiguration *configuration);
FOUNDATION_EXPORT NSString *WiFiDescriptionForCWNetworkProfile(CWNetworkProfile *profile);

#endif

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
#if TARGET_OS_OSX
+ (instancetype)instanceWithInterface:(CWInterface *)interface;
#endif
@end
