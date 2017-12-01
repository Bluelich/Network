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
#import <UIKit/UIKit.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

typedef NS_ENUM(NSUInteger, NetworkStatus) {
    NotReachable = 0,
    ReachableViaWiFi,
    ReachableVia2G,
    ReachableVia3G,
    ReachableVia4G
};
NetworkStatus NetworkStatusFromRadioAccess(NSString *radioAccessTechnology){
    /*
     CTRadioAccessTechnologyGPRS
     CTRadioAccessTechnologyEdge
     CTRadioAccessTechnologyWCDMA
     CTRadioAccessTechnologyHSDPA
     CTRadioAccessTechnologyHSUPA
     CTRadioAccessTechnologyCDMA1x
     CTRadioAccessTechnologyCDMAEVDORev0
     CTRadioAccessTechnologyCDMAEVDORevA
     CTRadioAccessTechnologyCDMAEVDORevB
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
static dispatch_queue_t reachabilityQueue = nil;

@interface NetWorkStatusManager ()
@property (nonatomic,assign) NetworkStatus  status;
@property (nonatomic,  copy) NSString  *ssid;
@property (nonatomic) SCNetworkReachabilityRef reachabilityRef;
@property (nonatomic,strong) CTTelephonyNetworkInfo  *telephonyNetworkInfo;
@end
@implementation NetWorkStatusManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.reachabilityRef = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, @"www.apple.com".UTF8String);
        self.telephonyNetworkInfo = [CTTelephonyNetworkInfo new];
        [self updateStatus];
        [self startNotify];
    }
    return self;
}
- (void)updateStatus
{
    SCNetworkReachabilityFlags flags = 0;
    if (!SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
        return;
    }
    self.status = [self reachabilityFlags:flags];
    if (self.status != ReachableViaWiFi) {
        return;
    }
    // change bssid
    NSArray *ifs = (id)CFBridgingRelease(CNCopySupportedInterfaces());
    for (NSString *ifnam in ifs) {
        id info = (id)CFBridgingRelease(CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam));
        NSString *bssidValue = [info objectForKey:(NSString *)kCNNetworkInfoKeyBSSID];
        NSString *ssidValue = [info objectForKey:(NSString *)kCNNetworkInfoKeySSID];
        if (bssidValue.length <= 0) {
            continue;
        }
        _ssid = [NSString stringWithFormat:@"%@-%@", ssidValue, bssidValue];
    }
}
// 网络变化回调函数
static void NetWorkStatusManagerReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info){
    //    NetworkManager *instance = [NetworkManager instance];
    //    [instance update];
}
- (void)startNotify
{
    [self notifyNetworkStatus];
    [self notifySimCard];
}
- (void)notifyNetworkStatus
{
    SCNetworkReachabilityContext context = { 0,
                                             (__bridge void *)(self),
                                             NULL,
                                             NULL,
                                             NULL
                                            };
    if (!SCNetworkReachabilitySetCallback(self.reachabilityRef, NetWorkStatusManagerReachabilityCallback, &context)) {
        return;
    }
    reachabilityQueue = dispatch_queue_create("com.bluelich.NetWorkStatusManagerQueue", DISPATCH_QUEUE_SERIAL);
    SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, reachabilityQueue);
}
- (void)notifySimCard
{
    [self.telephonyNetworkInfo setSubscriberCellularProviderDidUpdateNotifier:^(CTCarrier * _Nonnull carrier) {
        
    }];
    /*
     IMSI：International Mobile Subscriber Identification Number 国际移动用户识别码
     1.MCC(Mobile Country Code
     移动国家码)，MCC的资源由国际电联(ITU)统一分配，唯一识别移动用户所属的国家，MCC共3位，中国地区的MCC为460
     2.MNC(Mobile Network Code 移动网络号码)，用于识别移动客户所属的移动网络运营商。MNC由二到三个十进制数组成，例如中国移动MNC为00、02、07，中国联通的MNC为01、06、09，中国电信的MNC为03、05、11
     由1、2两点可知，对于中国地区来说IMSI一般为46000(中国移动)、46001(中国联通)、46003(中国电信)等
     */
    /*
     MCC--- 移动国家号码，由3位数字组成，唯一地识别移动客户所属的国家。我国 为460。
     
     定义：移动国家号(MCC)由三位十进制数组成，它表明移动用户(或系统)归属的国家。
     格式：移动国家号(MCC)由三个十进制数组成，编码范围为十进制的000－999
     传送：移动国家号用于国际移动用户识别(IMSI)中和位置区识别(LAI)中。
     MNC--- 移动网号，由2位数字组成，用于识别移动客户所归属的移动网。 中国移动GSM PLMN网为00，中国联通GSMPLMN网为0l。
     定义:移动网号(MNC)是一组十进制码，用以唯一地表示某个国家(由MCC确定)内的某一个特定的GSM PLMN网。
     格式:移动网号(MNC)由二个十进制数组成，编码范围为十进制的00－99。
     传送:移动网号用于国际移动用户识别(IMSI)和位置区识别(LAI)之中。
     
     位置区识别(LAI):位置区识别在每个小区广播的系统消息中周期发送，其中的移动网号(MNC)表示GSMPLMN的网络号。移动台将接收到的该信息作为网络选择的重要依据之一。
     移动台的IMSI：移动台的IMSI中同样包含了移动网号(MNC)，它表示该移动用户所属的GSMPLMN网。当移动台在网络上登录或申请某种业务时，移动台必须将IMSI报告给网络(在不能使用IMIS的情况下)。网络则根据IMSI中的移动网号(MNC)来判断该用户是否为漫游用户，并将MNC作为寻址用户HLR的重要参数之一。
     设置及影响：作为全球唯一的国家识别标准，MCC的资源由国际电联(ITU)统一分配和管理。ITU建议书E.212(兰皮书)规定了各国的MCC号码。由于MCC的特殊意义，因此它在网络中一旦设定之后是不允许更改的。 若一个国家中有多于一个的GSM公司陆地移动网(PLMN)，则每个网必须具有不同的MNC。MNC一般由国家的有关电信管理部门统一分配，同一个营运者可以拥有一个或多个MNC(视业务提供的规模而定)，但不同的营运者不可以分享相同的MNC。
     各国及地区GSN网络代码表........
     */
    CTCarrier *carrier = self.telephonyNetworkInfo.subscriberCellularProvider;
    NSString *mcc  = carrier.mobileCountryCode;//460
    NSString *mnc  = carrier.mobileNetworkCode;
    NSString *name = carrier.carrierName;
    NSString *icc  = carrier.isoCountryCode;
    BOOL allowVoip = carrier.allowsVOIP;
    NSString *imsi = [NSString stringWithFormat:@"%@%@", mcc, mnc];
    if ([mcc isEqualToString:@"466"]) {
        NSLog(@"中国移动通信运营商");
        NSArray<NSString *> *ChinaMobile  = @[@"00",@"02",@"07"];
        NSArray<NSString *> *ChinaUnicom  = @[@"01",@"06",@"09"];
        NSArray<NSString *> *ChinaTelecom = @[@"03",@"05",@"11"];
        if (mnc) {
            if ([ChinaMobile containsObject:mnc]) {
                
            }
        }
    }
}
#pragma mark -
- (NetworkStatus)reachabilityFlags:(SCNetworkReachabilityFlags)flags
{
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0 || ![self internetConnection]) {
        // The target host is not reachable.
        return NotReachable;
    }
    
    NetworkStatus returnValue = NotReachable;
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
        returnValue = ReachableViaWiFi;
    }
    
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            returnValue = ReachableViaWiFi;
        }
    }
    
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
        returnValue = ReachableVia4G;
    }
    BOOL isWWAN = (flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN;
    if (isWWAN) {
        BOOL isReachable = (flags & kSCNetworkReachabilityFlagsReachable) == kSCNetworkReachabilityFlagsReachable;
        if (isReachable) {
            BOOL supportTransientConnection = (flags & kSCNetworkReachabilityFlagsTransientConnection) == kSCNetworkReachabilityFlagsTransientConnection;
            if (supportTransientConnection) {
                returnValue = ReachableVia3G;
                BOOL a;
                /*
                 可以使用当前的网络配置来指定指定的节点名或地址，但必须首先建立连接。
                 如果这个标志被设置，该kscnetworkreachabilityflagsconnectionontraffic flag，
                 kscnetworkreachabilityflagsconnectionondemand flag，
                 或kscnetworkreachabilityflagsiswwan flag也通常设置为显示所需的连接类型。
                 如果用户必须手动进行连接，还需要设置的kscnetworkreachabilityflagsinterventionrequired flag。
                 */
                if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == kSCNetworkReachabilityFlagsConnectionRequired) {
                    returnValue = ReachableVia2G;
                }
            }
        }
    }
    if (kSCNetworkReachabilityFlagsTransientConnection){
        if(kSCNetworkReachabilityFlagsConnectionRequired){
            returnValue =  ReachableVia2G;
        }
        returnValue =  ReachableVia3G;
        return returnValue;
    }
    if (UIDevice.currentDevice.systemVersion.floatValue < 7.0f ||
        returnValue == ReachableViaWiFi ||
        !self.telephonyNetworkInfo.currentRadioAccessTechnology) {
        return returnValue;
    }
    NetworkStatus status = NetworkStatusFromRadioAccess(self.telephonyNetworkInfo.currentRadioAccessTechnology);
    if (status == ReachableVia4G ||
        status == ReachableVia3G) {
        return status;
    }
    return returnValue;
}
- (BOOL)internetConnection
{
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
    return (isReachable && !needsConnection) ? YES : NO;
}
/*
 * 判断当前网络状态下,是否有Http/Https代理
 */
+ (BOOL)hasProxy
{
    NSDictionary *proxySettings = CFBridgingRelease(CFNetworkCopySystemProxySettings());
    NSURL *url = [[NSURL alloc] initWithString:@"http://www.apple.com"];
    CFArrayRef array = CFNetworkCopyProxiesForURL((__bridge CFURLRef)url,
                                                  (__bridge CFDictionaryRef)proxySettings);
    NSArray *proxies = CFBridgingRelease(array);
    if (proxies.count == 0) {
        return NO;
    }
    NSDictionary *settings = proxies.firstObject;
    NSString *host = [settings objectForKey:(NSString *)kCFProxyHostNameKey];
    NSString *port = [settings objectForKey:(NSString *)kCFProxyPortNumberKey];
    if (host || port){
        return YES;
    }
    return NO;
}
@end
