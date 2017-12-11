//
//  NetWorkStatusManagerDefination.h
//  NetWork
//
//  Created by zhouqiang on 11/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import <Foundation/Foundation.h>
#if    TARGET_OS_IPHONE
    #import <UIKit/UIKit.h>
#endif
#import <SystemConfiguration/SystemConfiguration.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

typedef NS_ENUM(NSInteger, NetworkStatus) {
    ReachableUnknow = -1,
    NotReachable    = 0,
    ReachableViaWiFi,
#if    TARGET_OS_IPHONE
    ReachableViaWWAN,
    ReachableVia2G,
    ReachableVia3G,
    ReachableVia4G
#endif
};

#if    TARGET_OS_IPHONE
NetworkStatus NetworkStatusFromRadioAccess(NSString *radioAccessTechnology);
#endif

FOUNDATION_EXPORT void __releaseCFObject__(CFTypeRef cf);
FOUNDATION_EXPORT BOOL ConnectedToInternet(void);
FOUNDATION_EXPORT BOOL NetworkHasAgentProxy(void);
FOUNDATION_EXPORT NetworkStatus NetworkStatusForFlags(SCNetworkReachabilityFlags flags);



