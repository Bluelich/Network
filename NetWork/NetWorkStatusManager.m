//
//  NetWorkStatusManager.m
//  NetWork
//
//  Created by zhouqiang on 30/11/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import "NetWorkStatusManager.h"
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
#import "IMSIManager.h"
#if    TARGET_OS_IPHONE
    #import <UIKit/UIKit.h>
#endif
typedef NS_ENUM(NSInteger, NetworkStatus) {
    ReachableUnknow = -1,
    NotReachable    = 0,
    ReachableViaWiFi,
    ReachableViaWWAN,
    ReachableVia2G,
    ReachableVia3G,
    ReachableVia4G
};
NetworkStatus NetworkStatusFromRadioAccess(NSString *radioAccessTechnology){
    /*
     //2G
     CTRadioAccessTechnologyGPRS
     CTRadioAccessTechnologyEdge
     //3G
     CTRadioAccessTechnologyWCDMA
     CTRadioAccessTechnologyHSDPA
     CTRadioAccessTechnologyHSUPA
     CTRadioAccessTechnologyCDMA1x
     CTRadioAccessTechnologyCDMAEVDORev0
     CTRadioAccessTechnologyCDMAEVDORevA
     CTRadioAccessTechnologyCDMAEVDORevB
     //4G
     CTRadioAccessTechnologyeHRPD
     CTRadioAccessTechnologyLTE
     */
    if (!radioAccessTechnology) {
        return NotReachable;
    }
    if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE] ||
        [radioAccessTechnology isEqualToString:CTRadioAccessTechnologyeHRPD]) {
        return ReachableVia4G;
    }else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge]||
              [radioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS]){
        return ReachableVia2G;
    }else{
        return ReachableVia3G;
    }
}
BOOL ConnectedToInternet(){
    //创建0.0.0.0的地址,查询本机网络连接状态
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    if (!didRetrieveFlags) {
        return NO;
    }
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    return isReachable && !needsConnection;
}
static NetworkStatus NetworkStatusForFlags(SCNetworkReachabilityFlags flags) {
    /*!
     TransientConnection:指定的节点或地址可以通过瞬态连接(如PPP)到达。
     Reachable:指定的节点或地址可以使用当前网络配置进行访问。
     ConnectionRequired:须先建立连接.ConnectionOnTraffic,ConnectionOnDemand,IsWWAN通常也会被设置.如果用户必须手动进行连接,则还会设置InterventionRequired
     例如,这个状态将返回一个拨号当前未激活的连接, 但可以处理目标系统的网络通信量。
     ConnectionOnTraffic:须先建立连接.任何传输指示指定的名称或地址将启动连接。
     InterventionRequired:须先建立连接.此外,需要用户操作来建立连接,如提供密码、身份验证等。
     注: 目前,会返回 仅在配置kSCNetworkReachabilityFlagsConnectionOnTraffic时,已尝试连接,并在尝试自动连接时发生了错误.这时,PPP控制器将停止建立连接的尝试,直到用户干预。
     ConnectionOnDemand:须先建立连接。仅会通过CFSocketStream按需建立连接
     IsLocalAddress:本地连接
     IsDirect:不走网关,直连
     IsWWAN:蜂窝网络
     */
    BOOL isReachable = flags & kSCNetworkReachabilityFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkReachabilityFlagsConnectionRequired;
    BOOL canConnectAutomatically = ((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) ||
                                    (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic));
    BOOL canConnectWithoutUserInteraction = (canConnectAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
    BOOL isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction));
    if (!isNetworkReachable) {
        return NotReachable;
    }
#if    TARGET_OS_IPHONE
    else if (flags & kSCNetworkReachabilityFlagsIsWWAN){
        return ReachableViaWWAN;
    }
#endif
    else{
        return ReachableViaWiFi;
    }
}
/*
 * 判断当前网络状态下,是否有HTTP/HTTPS代理
 */
BOOL NetworkHasAgentProxy(){
    CFStringRef domain = CFStringCreateWithCString(kCFAllocatorDefault, "http://www.apple.com", kCFStringEncodingUTF8);
    CFURLRef url = CFURLCreateWithString(kCFAllocatorDefault, domain, NULL);
    CFArrayRef proxies = CFNetworkCopyProxiesForURL(url,CFNetworkCopySystemProxySettings());
    CFIndex count = CFArrayGetCount(proxies);
    for (int idx = 0; idx < count; idx++) {
        CFDictionaryRef proxy = CFArrayGetValueAtIndex(proxies, idx);
        /*
         kCFProxyTypeKey -> CFStringRef
         kCFProxyTypeNone : directly
         kCFProxyTypeHTTP
         kCFProxyTypeHTTPS
         kCFProxyTypeSOCKS
         kCFProxyTypeFTP
         kCFProxyTypeAutoConfigurationURL - 由自动配置文件(pac)指定
         kCFProxyHostNameKey -> CFString
         kCFProxyPortNumberKey -> CFNumber
         kCFProxyAutoConfigurationURLKey -> CFURL when proxyType:kCFProxyTypeAutoConfigurationURL
         kCFProxyAutoConfigurationJavaScriptKey -> CFString full JavaScript text
         kCFProxyUsernameKey -> CFString
         kCFProxyPasswordKey -> CFString
         kCFProxyTypeAutoConfigurationJavaScript -> kCFProxyTypeAutoConfigurationJavaScript
         kCFProxyAutoConfigurationHTTPResponseKey -> kCFProxyAutoConfigHTTPResponse
         //Mac Only
         kCFNetworkProxiesExceptionsList -> CFArray of CFStrings
         kCFNetworkProxiesExcludeSimpleHostnames -> CFNumber
         kCFNetworkProxiesFTPEnable -> CFNumber
         kCFNetworkProxiesFTPPassive -> CFNumber
         kCFNetworkProxiesFTPPort -> CFNumber
         kCFNetworkProxiesFTPProxy -> CFString
         kCFNetworkProxiesGopherEnable -> CFNumber
         kCFNetworkProxiesGopherPort -> CFNumber
         kCFNetworkProxiesGopherProxy -> CFString
         kCFNetworkProxiesHTTPEnable -> CFNumber
         kCFNetworkProxiesHTTPPort -> CFNumber
         kCFNetworkProxiesHTTPProxy -> CFString
         kCFNetworkProxiesHTTPSEnable -> CFNumber
         kCFNetworkProxiesHTTPSPort -> CFNumber
         kCFNetworkProxiesHTTPSProxy -> CFString
         kCFNetworkProxiesRTSPEnable -> CFNumber
         kCFNetworkProxiesRTSPPort -> CFNumber
         kCFNetworkProxiesRTSPProxy -> CFString
         kCFNetworkProxiesSOCKSEnable -> CFNumber
         kCFNetworkProxiesSOCKSPort -> CFNumber
         kCFNetworkProxiesSOCKSProxy -> CFString
         kCFNetworkProxiesProxyAutoConfigEnable -> CFNumber
         kCFNetworkProxiesProxyAutoConfigURLString -> CFString
         kCFNetworkProxiesProxyAutoConfigJavaScript -> CFString
         kCFNetworkProxiesProxyAutoDiscoveryEnable -> CFNumber
         */
        CFStringRef type = CFDictionaryGetValue(proxy, kCFProxyTypeKey);
        if (type != NULL && (type == kCFProxyTypeHTTP || type == kCFProxyTypeHTTPS)) {
            return YES;
        }
        CFStringRef host = CFDictionaryGetValue(proxy, kCFProxyHostNameKey);
        CFStringRef port = CFDictionaryGetValue(proxy, kCFProxyPortNumberKey);
        if (host != NULL || port != NULL){
            return YES;
        }
    }
    return NO;
}
@interface NetWorkStatusManager ()
@property (class,nonatomic,strong,readonly) NetWorkStatusManager *shared;
@property (nonatomic)dispatch_queue_t                 reachabilityQueue;
@property (nonatomic,assign) NetworkStatus            status;
@property (nonatomic,  copy) NSString                *ssid;
@property (nonatomic) SCNetworkReachabilityRef        reachabilityRef;
@property (nonatomic,strong) CTTelephonyNetworkInfo  *telephonyNetworkInfo;
@property (nonatomic,strong) PLMN  *cellularProvider;
@end
@implementation NetWorkStatusManager
+ (NetWorkStatusManager *)shared
{
    static dispatch_once_t onceToken;
    static NetWorkStatusManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [NetWorkStatusManager new];
        manager.reachabilityRef = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, @"www.apple.com".UTF8String);
        manager.telephonyNetworkInfo = [CTTelephonyNetworkInfo new];
        manager.reachabilityQueue = dispatch_queue_create("com.bluelich.NetWorkStatusManagerQueue", DISPATCH_QUEUE_SERIAL);
        [manager updateNetworkStatus];
        [manager updateSSID];
        [manager updateCellularProvider];
        [manager notifyNetworkStatus];
        [manager notifySimCard];
    });
    return manager;
}
- (void)updateSSID
{
    if (self.status != ReachableViaWiFi) {
        _ssid = nil;
        return;
    }
    /*
     SSID  = wifi name
     BSSID = mac address
     ESSID = same like BSSID
     */
    CFArrayRef interfaces = CNCopySupportedInterfaces();
    CFIndex count = CFArrayGetCount(interfaces);
    for (CFIndex i = 0; i < count; i++) {
        CFStringRef name = CFArrayGetValueAtIndex(interfaces, i);
        CFDictionaryRef info = CNCopyCurrentNetworkInfo(name);
        CFStringRef bssid = CFDictionaryGetValue(info, kCNNetworkInfoKeyBSSID);
        if (bssid == NULL) {
            continue;
        }
        CFDataRef data = CFDictionaryGetValue(info, kCNNetworkInfoKeySSIDData);
        printf("%p",data);
        CFStringRef ssid = CFDictionaryGetValue(info, kCNNetworkInfoKeySSID);
        CFIndex len_ssid = CFStringGetLength(ssid);
        char *ssid_cStr = malloc(len_ssid + 1);
        CFStringGetCString(ssid, ssid_cStr, len_ssid + 1, kCFStringEncodingUTF8);
        CFIndex len_bssid = CFStringGetLength(bssid);
        char *bssid_cStr = malloc(len_bssid + 1);
        CFStringGetCString(bssid, bssid_cStr, len_bssid + 1, kCFStringEncodingUTF8);
        unsigned long len = strlen(ssid_cStr) + strlen(bssid_cStr) + 2;
        char *str = malloc(len);
        snprintf(str, len, "%s-%s",ssid_cStr,bssid_cStr);
        _ssid = [NSString stringWithUTF8String:str];
    }
}
- (void)updateCellularProvider
{
    CTCarrier *carrier = self.telephonyNetworkInfo.subscriberCellularProvider;
    NSString *mcc  = carrier.mobileCountryCode;//460
    NSString *mnc  = carrier.mobileNetworkCode;//02
    NSString *name = carrier.carrierName;//中国移动
    NSString *icc  = carrier.isoCountryCode;//cn
    BOOL allowVoip = carrier.allowsVOIP;//YES
    printf("name:%s icc:%s voip:%s",name.UTF8String,icc.UTF8String,allowVoip ? "YES":"NO");
    self.cellularProvider = [IMSIManager infoForMCC:mcc MNC:mnc];
    if ([mcc isEqualToString:@"460"]) {
        if (mnc) {
            printf("\n中国");
            NSArray<NSString *> *ChinaMobile  = @[@"00",@"02",@"07"];
            NSArray<NSString *> *ChinaUnicom  = @[@"01",@"06",@"09"];
            NSArray<NSString *> *ChinaTelecom = @[@"03",@"05",@"11"];
            if ([ChinaMobile containsObject:mnc]) {
                printf("移动\n");
            }else if ([ChinaUnicom containsObject:mnc]) {
                printf("联通\n");
            }else if ([ChinaTelecom containsObject:mnc]) {
                printf("电信\n");
            }
        }
    }
}
- (void)updateNetworkStatus
{
    SCNetworkReachabilityFlags flags = 0;
    if (!SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
        return;
    }
    NetworkStatus status = NetworkStatusForFlags(flags);
#if    TARGET_OS_IPHONE
    if (status == ReachableViaWWAN && self.telephonyNetworkInfo && UIDevice.currentDevice.systemVersion.floatValue >= 7.0f) {
        status = NetworkStatusFromRadioAccess(self.telephonyNetworkInfo.currentRadioAccessTechnology);
    }
#endif
    self.status = status;
}
static const void *NetworkReachabilityRetainContextCallback(const void *info) {
    return Block_copy(info);
}
static void NetworkReachabilityReleaseContextCallback(const void *info) {
    !info ?: Block_release(info);
}
static CFStringRef NetworkReachabilityCopyDescriptionCallback(const void *info){
    return CFSTR("context is a block");
}
static void NetWorkStatusManagerReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info){
    [NetWorkStatusManager.shared updateSSID];
    [NetWorkStatusManager.shared updateCellularProvider];
    [NetWorkStatusManager.shared updateNetworkStatus];
}
- (void)notifyNetworkStatus
{
    if (!self.reachabilityRef) {
        return;
    }
    void(^block)(void) = ^{
        
    };
    CFIndex version = 0;
    void *info = (__bridge void *)block;
    SCNetworkReachabilityContext context = {version,info,
                                            NetworkReachabilityRetainContextCallback,
                                            NetworkReachabilityReleaseContextCallback,
                                            NetworkReachabilityCopyDescriptionCallback};
    Boolean success = SCNetworkReachabilitySetCallback(self.reachabilityRef, NetWorkStatusManagerReachabilityCallback, &context);
    if (!success) {
        return;
    }
    SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, self.reachabilityQueue);
    SCNetworkReachabilityScheduleWithRunLoop(self.reachabilityRef, CFRunLoopGetMain(), kCFRunLoopCommonModes);
}
- (void)notifySimCard
{
    __weak typeof(self) weakSelf = self;
    [self.telephonyNetworkInfo setSubscriberCellularProviderDidUpdateNotifier:^(CTCarrier * _Nonnull carrier) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf updateCellularProvider];
    }];
}
@end
/*
 ATS
 只针对公共域名起效,对 [IP地址 | 非法域名 | 使用.local作为顶级域名的本地主机] 无效
 
 NSAppTransportSecurity : Dictionary {
     NSAllowsArbitraryLoads : Boolean //NO
     NSAllowsArbitraryLoadsInMedia : Boolean //YES
     NSAllowsArbitraryLoadsInWebContent : Boolean //NO
     NSAllowsLocalNetworking : Boolean //NO
     NSExceptionDomains : Dictionary {
         <domain-name-string> : Dictionary {
             NSIncludesSubdomains : Boolean //NO
             NSExceptionAllowsInsecureHTTPLoads : Boolean //NO
             NSExceptionMinimumTLSVersion : String
             NSExceptionRequiresForwardSecrecy : Boolean //YES
             NSRequiresCertificateTransparency : Boolean //NO
         }
     }
 }
 */
