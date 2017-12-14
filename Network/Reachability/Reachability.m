//
//  Reachability.m
//  Network
//
//  Created by zhouqiang on 14/12/2017.
//

#import "Reachability.h"

@interface Reachability ()
@property (nonatomic)dispatch_queue_t                 reachabilityQueue;
@property (nonatomic) SCNetworkReachabilityRef        reachabilityRef;
#if TARGET_OS_IPHONE
@property (nonatomic,strong) CTTelephonyNetworkInfo  *telephonyNetworkInfo;
#endif
@property (nonatomic,  copy) NSString                *ssid;
@property (nonatomic,assign) NetworkStatus            status;
@property (nonatomic,strong) IMSI                    *cellularProvider;
@property (nonatomic,strong) WiFi                    *WiFiInfo;
@end

@implementation Reachability
+ (Reachability *)shared
{
    static dispatch_once_t onceToken;
    static Reachability *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[Reachability alloc] init];
        manager.reachabilityRef      = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, @"www.apple.com".UTF8String);
        manager.reachabilityQueue    = dispatch_queue_create("com.bluelich.reachability.queue", DISPATCH_QUEUE_SERIAL);
        if (manager.reachabilityRef && manager.reachabilityQueue) {
            SCNetworkReachabilitySetDispatchQueue(manager.reachabilityRef, manager.reachabilityQueue);
        }
#if TARGET_OS_IPHONE
        manager.telephonyNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
#endif
        [manager update];
        [manager notify];
    });
    return manager;
}
- (void)update
{
    [self updateNetworkStatus];
#if TARGET_OS_IPHONE
    [self updateSSID];
#endif
    [self updateCellularProvider];
}
- (void)notify
{
    [self notifyNetworkStatus];
    [self notifySimCard];
}
- (void)updateSSID
{
    if (self.status != ReachableViaWiFi) {
        self.WiFiInfo = nil;
        return;
    }
#if TARGET_OS_IPHONE
    CFArrayRef interfaces = CNCopySupportedInterfaces();
    if (!interfaces) {
        return;
    }
    CFIndex count = CFArrayGetCount(interfaces);
    for (CFIndex i = 0; i < count; i++) {
        CFStringRef name = CFArrayGetValueAtIndex(interfaces, i);
        CFDictionaryRef info = CNCopyCurrentNetworkInfo(name);
        if (CFDictionaryGetCount(info) == 0) {
            continue;
        }
        NSString *ssid  = (__bridge NSString *)CFDictionaryGetValue(info, kCNNetworkInfoKeySSID);
        NSString *bssid = (__bridge NSString *)CFDictionaryGetValue(info, kCNNetworkInfoKeyBSSID);
        NSData   *data  = (__bridge NSData   *)CFDictionaryGetValue(info, kCNNetworkInfoKeySSIDData);
        self.WiFiInfo = [[WiFi alloc] initWithSSID:ssid BSSID:bssid SSIDData:data];
    }
#endif
}
- (void)updateNetworkStatus
{
    SCNetworkReachabilityFlags flags = 0;
    /*
     SCNetworkReachabilityGetFlags是同步的,通过DNS解析来判定网络状况
     在DNS服务器无法到达或慢速网络上,可能耗时30s以上
     如果在主线程调用这个函数,20s无响应,则会被watchdog杀死
     SCNetworkReachability API 目前不提供检测设备级p2p网络支持的方法,包括Multipeer Connectivity、GameKit、Game Center 和 p2p NSNetService。
     */
    if (!SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
        return;
    }
    NetworkStatus status = NetworkStatusForFlags(flags);
#if TARGET_OS_IPHONE
    if (status == ReachableViaWWAN && self.telephonyNetworkInfo && UIDevice.currentDevice.systemVersion.floatValue >= 7.0f) {
        status = NetworkStatusFromRadioAccess(self.telephonyNetworkInfo.currentRadioAccessTechnology);
    }
#endif
    self.status = status;
}
- (void)updateCellularProvider
{
#if TARGET_OS_IPHONE
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
#endif
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
    [Reachability.shared update];
    void(^block)(NetworkStatus status) = (__bridge void(^)(NetworkStatus status))info;
    !block ?: block(Reachability.shared.status);
}
- (BOOL)notifyNetworkStatus
{
    if (!self.reachabilityRef) {
        return NO;
    }
    __weak typeof(self) weakSelf = self;
    void(^block)(NetworkStatus status) = ^(NetworkStatus status){
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.status = status;
        NSLog(@"");
    };
    CFIndex version = 0;
    void *info = (__bridge void *)block;
    SCNetworkReachabilityContext context = {version,info,
        NetworkReachabilityRetainContextCallback,
        NetworkReachabilityReleaseContextCallback,
        NetworkReachabilityCopyDescriptionCallback};
    if (SCNetworkReachabilitySetCallback(self.reachabilityRef, NetWorkStatusManagerReachabilityCallback, &context) &&
        SCNetworkReachabilityScheduleWithRunLoop(self.reachabilityRef, CFRunLoopGetMain(), kCFRunLoopCommonModes)) {
        return YES;
    }
    return NO;
}
- (void)notifySimCard
{
#if TARGET_OS_IPHONE
    if (self.telephonyNetworkInfo) {
        __weak typeof(self) weakSelf = self;
        self.telephonyNetworkInfo.subscriberCellularProviderDidUpdateNotifier = ^(CTCarrier * _Nonnull carrier){
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf updateCellularProvider];
        };
    }
#endif
}
- (void)stopNotify
{
#if TARGET_OS_IPHONE
    self.telephonyNetworkInfo.subscriberCellularProviderDidUpdateNotifier = nil;
#endif
    if (self.reachabilityRef) {
        SCNetworkReachabilityUnscheduleFromRunLoop(self.reachabilityRef, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    }
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

