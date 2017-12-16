//
//  ReachabilityDefination.h
//  Network
//
//  Created by zhouqiang on 14/12/2017.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#if TARGET_OS_IPHONE
    #import <CoreTelephony/CTTelephonyNetworkInfo.h>
    #import <CoreTelephony/CTCarrier.h>
    #import <UIKit/UIKit.h>
#endif

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <netdb.h>
#import <arpa/inet.h>
#import <ifaddrs.h>

#import <sys/socket.h>
#import <sys/sockio.h>
#import <sys/ioctl.h>
#import <sys/types.h>
#import <sys/errno.h>

#import <net/if.h>
#import <net/if_dl.h>
#import <net/ethernet.h>

#import <stdio.h>
#import <stdlib.h>
#import <unistd.h>

#import "Addr_Interface.h"

typedef NS_ENUM(NSInteger, NetworkStatus) {
    NotReachable    = 0,
    ReachableViaWiFi,
#if TARGET_OS_IPHONE
    ReachableViaWWAN,
    ReachableVia2G,
    ReachableVia3G,
    ReachableVia4G
#endif
};

FOUNDATION_EXPORT void __releaseCFObject__(CFTypeRef cf);
FOUNDATION_EXPORT BOOL ConnectedToInternet(Address_format format);
FOUNDATION_EXPORT BOOL NetworkHasAgentProxy(void);
FOUNDATION_EXPORT NetworkStatus NetworkStatusForFlags(SCNetworkReachabilityFlags flags);
FOUNDATION_EXPORT NSString *NSStringFromNetworkStatus(NetworkStatus status);
#if TARGET_OS_IPHONE
    NetworkStatus NetworkStatusFromRadioAccess(NSString *radioAccessTechnology);
#endif

