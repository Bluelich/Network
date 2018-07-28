//
//  ReachabilityDefination.m
//  Network
//
//  Created by zhouqiang on 14/12/2017.
//

#import "ReachabilityDefination.h"
#import <CFNetwork/CFProxySupport.h>
#import <YYModel/YYModel.h>
#import <JavaScriptCore/JavaScriptCore.h>

BOOL ConnectedToInternet(Address_format prefer_format){
    BOOL ipv6 = prefer_format & Address_format_ipv6;
    if (!ipv6 && prefer_format == Address_format_other) {
        if (@available(macOS 10.11,iOS 9.0, *)) {
            ipv6 = YES;
        }
    }
    //创建0.0.0.0的地址,查询本机网络连接状态
    struct sockaddr *address;
    if (ipv6) {
        struct sockaddr_in6 address_6;
        bzero(&address_6, sizeof(struct sockaddr_in6));
        address_6.sin6_len = sizeof(struct sockaddr_in6);
        address_6.sin6_family = AF_INET6;
        address = (struct sockaddr *)&address_6;
    }else{
        struct sockaddr_in address_4;
        bzero(&address_4, sizeof(struct sockaddr_in));//置0同memset
        address_4.sin_len = sizeof(struct sockaddr_in);
        address_4.sin_family = AF_INET;
        address = (struct sockaddr *)&address_4;
    }
    
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, address);
    SCNetworkReachabilityFlags flags;
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    !defaultRouteReachability ?: CFRelease(defaultRouteReachability);
    if (!didRetrieveFlags) {
        return NO;
    }
    BOOL isReachable     = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    return isReachable && !needsConnection;
}
NSString *NSStringFromNetworkStatus(NetworkStatus status){
    switch (status) {
        case NotReachable:
            return @"NotReachable";
        case ReachableViaWiFi:
            return @"ReachableViaWiFi";
#if TARGET_OS_IPHONE
        case ReachableViaWWAN:
            return @"ReachableViaWWAN";
        case ReachableVia2G:
            return @"ReachableVia2G";
        case ReachableVia3G:
            return @"ReachableVia3G";
        case ReachableVia4G:
            return @"ReachableVia4G";
#endif
    }
}
NetworkStatus NetworkStatusForFlags(SCNetworkReachabilityFlags flags) {
    /*
     PPP:Point-To-Point,点对点通信协议
     TransientConnection:指定的节点或地址可以通过瞬态连接(如p2p)到达。
     Reachable:指定的节点或地址可以使用当前网络配置进行访问。
     ConnectionRequired:需先建立连接.ConnectionOnTraffic,ConnectionOnDemand,IsWWAN通常也会被设置.
     如果用户必须手动进行连接,还会设置InterventionRequired
     例如,这个状态将返回一个拨号当前未激活的连接, 但可以处理目标系统的网络通信量。
     ConnectionOnTraffic:需先建立连接.任何传输指示指定的名称或地址将启动连接。
     InterventionRequired:需先建立连接.此外,需要用户干预来建立连接,如提供密码、身份验证等。
     注: 目前,仅在配置kSCNetworkReachabilityFlagsConnectionOnTraffichou,已尝试连接,并在尝试自动连接时发生了错误时会返回.这时,p2p控制器将停止建立连接的尝试,直到用户干预。
     ConnectionOnDemand:需先建立连接。仅会通过CFSocketStream按需建立连接
     IsLocalAddress:本地连接
     IsDirect:不走网关,直连
     IsWWAN:蜂窝网络
     */
    BOOL isReachable = flags & kSCNetworkReachabilityFlagsReachable;
    if (!isReachable) {
        return NotReachable;
    }
    NetworkStatus status = NotReachable;
    BOOL needsConnection = flags & kSCNetworkReachabilityFlagsConnectionRequired;
    if (!needsConnection) {
        //如果reachable且不需要先建立连接,则可以先假定为Wifi
        status = ReachableViaWiFi;
    }
    //如果调用的是CFSocketStream或更高级的API,则连接是ConnectionOnDemand或ConnectionOnTraffic
    BOOL canConnectAutomatically = ((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) ||
                                    (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic));
    BOOL interventionRequired = flags & kSCNetworkReachabilityFlagsInterventionRequired;
    BOOL canConnectWithoutUserInteraction = (canConnectAutomatically && !interventionRequired);
    if (canConnectWithoutUserInteraction) {
        //如果不需要用户的干预就可以连接,则是Wi-Fi
        status = ReachableViaWiFi;
    }
#if TARGET_OS_IPHONE
    if (flags & kSCNetworkReachabilityFlagsIsWWAN){
        //如果调用应用程序使用的是CFNetwork的API,WWAN连接是可用的。
        status = ReachableViaWWAN;
    }
#endif
    return status;
}
#if TARGET_OS_IPHONE
NetworkStatus NetworkStatusFromRadioAccess(NSString *radioAccessTechnology){
    if (![radioAccessTechnology isKindOfClass:NSString.class] || radioAccessTechnology.length == 0) {
        return NotReachable;
    }
    static NSArray *WWAN_2G = nil;
    static NSArray *WWAN_3G = nil;
    static NSArray *WWAN_4G = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        WWAN_2G = @[CTRadioAccessTechnologyGPRS,
                    CTRadioAccessTechnologyEdge];
        WWAN_3G = @[CTRadioAccessTechnologyWCDMA,
                    CTRadioAccessTechnologyHSDPA,
                    CTRadioAccessTechnologyHSUPA,
                    CTRadioAccessTechnologyCDMA1x,
                    CTRadioAccessTechnologyCDMAEVDORev0,
                    CTRadioAccessTechnologyCDMAEVDORevA,
                    CTRadioAccessTechnologyCDMAEVDORevB];
        WWAN_4G = @[CTRadioAccessTechnologyeHRPD,
                    CTRadioAccessTechnologyLTE];
    });
    if ([WWAN_4G containsObject:radioAccessTechnology]) {
        return ReachableVia4G;
    }else if ([WWAN_3G containsObject:radioAccessTechnology]){
        return ReachableVia3G;
    }else if ([WWAN_2G containsObject:radioAccessTechnology]){
        return ReachableVia2G;
    }else{
        //Maybe 5G
        return ReachableViaWWAN;
    }
}
#endif

#if TARGET_OS_MAC
@interface NetworkProxyAttr : NSObject
//FTP Gopher HTTP HTTPS RTSP SOCKS
@property (nonatomic,copy) NSString  *type;
@property (nonatomic,copy) NSNumber  *enable;// value && value != 0
@property (nonatomic,copy) NSNumber  *port;
@property (nonatomic,copy) NSString  *proxy;
@property (nonatomic,copy) NSNumber  *passive;//For FTP only
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new  NS_UNAVAILABLE;
@end
@implementation NetworkProxyAttr
- (instancetype)initWithType:(NSString *)type Attributes:(NSDictionary *)info
{
    self = [super init];
    if (self) {
        self.type = type;
        [self parser:info];
    }
    return self;
}
- (void)parser:(NSDictionary *)info
{
    if (!self.type) {
        return;
    }
    NSMutableDictionary<NSString *,NSString *> *attrs =
     @{@"enable":[@"kCFNetworkProxies[]Enable" stringByReplacingOccurrencesOfString:@"[]" withString:self.type],
       @"port"  :[@"kCFNetworkProxies[]Port" stringByReplacingOccurrencesOfString:@"[]" withString:self.type],
       @"proxy" :[@"kCFNetworkProxies[]Proxy" stringByReplacingOccurrencesOfString:@"[]" withString:self.type]
       }.mutableCopy;
    if ([self.type isEqualToString:@"FTP"]) {
        attrs[@"passive"] = [@"kCFNetworkProxies[]Passive" stringByReplacingOccurrencesOfString:@"[]" withString:self.type];
    }
    [attrs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [self setValue:info[obj] forKey:key];
    }];
}
@end
@interface NetworkProxyPACAttr : NSObject
@property (nonatomic,copy) NSNumber  *enable;
@property (nonatomic,copy) NSString  *URLString;
@property (nonatomic,copy) NSString  *fullJavaScriptText;
@property (nonatomic,copy) NSNumber  *discoveryEnable;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new  NS_UNAVAILABLE;
@end
@implementation NetworkProxyPACAttr
- (instancetype)initWithAttributes:(NSDictionary *)info
{
    self = [super init];
    if (self) [self parser:info];
    return self;
}
- (void)parser:(NSDictionary *)info
{
    NSString *CFNetworkPACJavaScript = @"kCFNetworkProxiesProxyAutoConfigJavaScript";
    NSDictionary<NSString *,NSString *> *attrs =
    @{@"enable"             :(__bridge NSString *)kCFNetworkProxiesProxyAutoConfigEnable,
      @"URLString"          :(__bridge NSString *)kCFNetworkProxiesProxyAutoConfigURLString,
      @"fullJavaScriptText" :CFNetworkPACJavaScript,
      @"discoveryEnable"    :(__bridge NSString *)kCFNetworkProxiesProxyAutoDiscoveryEnable};
    [attrs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [self setValue:info[obj] forKey:key];
    }];
}
@end
#endif

typedef NS_ENUM(NSUInteger, NetworkProxyType) {
    NetworkProxyTypeUnknow = 0,
    NetworkProxyTypeNone,//directly
    NetworkProxyTypeHTTP,
    NetworkProxyTypeHTTPS,
    NetworkProxyTypeSOCKS,
    NetworkProxyTypeFTP,
    NetworkProxyTypeAutoConfigurationURL, //pac
    NetworkProxyTypeAutoConfigurationJavaScript
};
NetworkProxyType NetworkProxyTypeForProxy(NSString *proxy){
    if (!proxy) return NetworkProxyTypeUnknow;
    CFStringRef proxyref = (__bridge CFStringRef)proxy;
    CFStringCompareFlags compareOptions = kCFCompareCaseInsensitive;
    if (!CFStringCompare(proxyref, kCFProxyTypeNone, compareOptions)) {
        return NetworkProxyTypeNone;
    }else if (!CFStringCompare(proxyref, kCFProxyTypeHTTP, compareOptions)) {
        return NetworkProxyTypeHTTP;
    }else if (!CFStringCompare(proxyref, kCFProxyTypeHTTPS, compareOptions)) {
        return NetworkProxyTypeHTTPS;
    }else if (!CFStringCompare(proxyref, kCFProxyTypeSOCKS, compareOptions)) {
        return NetworkProxyTypeSOCKS;
    }else if (!CFStringCompare(proxyref, kCFProxyTypeFTP, compareOptions)) {
        return NetworkProxyTypeFTP;
    }else if (!CFStringCompare(proxyref, kCFProxyTypeAutoConfigurationURL, compareOptions)) {
        return NetworkProxyTypeAutoConfigurationURL;
    }else if (!CFStringCompare(proxyref, kCFProxyTypeAutoConfigurationJavaScript, compareOptions)) {
        return NetworkProxyTypeAutoConfigurationJavaScript;
    }
    return NetworkProxyTypeUnknow;
}
@interface NetworkSystemProxySettings : NSObject
@property (nonatomic,assign) NetworkProxyType  proxyType;
@property (nonatomic,  copy) NSString  *hostName;
@property (nonatomic,  copy) NSNumber  *portNumber;
@property (nonatomic,  copy) NSURL     *PACURL;
@property (nonatomic,  copy) NSString  *PACJavaScript;
@property (nonatomic,  copy) NSString  *username;
@property (nonatomic,  copy) NSString  *password;
@property CFHTTPMessageRef PACHTTPResponseForAuthError;
#if TARGET_OS_MAC
@property (nonatomic,  copy) NSArray<NSString *> *exceptionsList;
@property (nonatomic,  copy) NSNumber  *excludeSimpleHostnames;
@property (nonatomic,strong) NetworkProxyAttr     *FTPAtts;
@property (nonatomic,strong) NetworkProxyAttr     *GopherAtts;
@property (nonatomic,strong) NetworkProxyAttr     *HTTPAttrs;
@property (nonatomic,strong) NetworkProxyAttr     *HTTPSAttrs;
@property (nonatomic,strong) NetworkProxyAttr     *RTSPAttrs;
@property (nonatomic,strong) NetworkProxyAttr     *SOCKSAttrs;
@property (nonatomic,strong) NetworkProxyPACAttr  *PACAttrs;
#endif
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new  NS_UNAVAILABLE;
@end
@implementation NetworkSystemProxySettings
- (instancetype)initWithAttributes:(NSDictionary *)info
{
    self = [super init];
    if (self) [self parser:info];
    return self;
}
- (void)parser:(NSDictionary *)info
{
    static NSDictionary<NSString *,NSString *> *attrs = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        attrs = @{@"hostName":(__bridge NSString *)kCFProxyHostNameKey,
                  @"portNumber":(__bridge NSString *)kCFProxyPortNumberKey,
                  @"PACURL":(__bridge NSString *)kCFProxyAutoConfigurationURLKey,
                  @"PACJavaScript":(__bridge NSString *)kCFProxyAutoConfigurationJavaScriptKey,
                  @"username":(__bridge NSString *)kCFProxyUsernameKey,
                  @"password":(__bridge NSString *)kCFProxyPasswordKey,
#if ! TARGET_OS_IPHONE && TARGET_OS_MAC
                  @"exceptionsList":(__bridge NSString *)kCFNetworkProxiesExceptionsList,
                  @"excludeSimpleHostnames":(__bridge NSString *)kCFNetworkProxiesExcludeSimpleHostnames,
#endif
                  };
    });
    NSString *CFPACHTTPResponseKey = @"kCFProxyAutoConfigurationHTTPResponse";
    NSString *proxy = info[(__bridge NSString *)kCFProxyTypeKey];
    self.proxyType = NetworkProxyTypeForProxy(proxy);
    id obj = info[CFPACHTTPResponseKey];
    if (obj) {
        self.PACHTTPResponseForAuthError = (__bridge CFHTTPMessageRef)obj;
    }
    [attrs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [self setValue:info[obj] forKey:key];
    }];
}
@end
/*
 * 判断当前网络状态下,是否有HTTP/HTTPS代理
 */
BOOL NetworkHasAgentProxyFor(NSDictionary *dic){
    return NO;
}
BOOL NetworkHasAgentProxy(NSString *host){
    if (!host) return NO;
    NSURL *url = [NSURL URLWithString:host];
    if (!url) return NO;
    NSDictionary *systemProxySettings = (__bridge NSDictionary *)CFNetworkCopySystemProxySettings();
    if (!systemProxySettings.count) {
        return NO;
    }
    NSArray<NSDictionary *> *proxies = (__bridge NSArray *)CFNetworkCopyProxiesForURL((__bridge CFURLRef)(url),(__bridge CFDictionaryRef)systemProxySettings);
    if (!proxies) return NO;
    for (NSDictionary * _Nonnull obj in proxies) {
        NSString *type = ([obj objectForKey:(__bridge NSString *)kCFProxyTypeKey]);
        if (type == (__bridge NSString *)kCFProxyTypeHTTP  ||
            type == (__bridge NSString *)kCFProxyTypeHTTPS) {
            printf("----- [type] -----");
            return YES;
        }else {
            NSString *host = [obj objectForKey:(__bridge NSString *)kCFProxyHostNameKey];
            NSNumber *port = [obj objectForKey:(__bridge NSString *)kCFProxyPortNumberKey];
            if (host.length && port.stringValue.length) {
                printf("----- [host:%s port:%s] -----",host.UTF8String,port.stringValue.UTF8String);
                return YES;
            }
        }
    }
    NSString *urlString = [systemProxySettings objectForKey:(__bridge NSString *)kCFNetworkProxiesProxyAutoConfigURLString];
    if (!urlString) {
        urlString = [systemProxySettings objectForKey:(__bridge NSString *)kCFProxyAutoConfigurationURLKey];
    }
    if (urlString) {
        //PAC文件
        NSError *error= nil;
        NSString *js_pac = [NSString stringWithContentsOfURL:[NSURL URLWithString:urlString] encoding:NSUTF8StringEncoding error:&error];
        if (!error && js_pac) {
            JSContext *context = [JSContext new];
            JSValue *value = [context evaluateScript:js_pac];
            NSString *findProxyForURL_url_host = [NSString stringWithFormat:@"FindProxyForURL('%@','%@')",url.absoluteString,url.host];
            value = [context evaluateScript:findProxyForURL_url_host];
            static NSString *direct = @"DIRECT;";
            NSString *proxy = value.toString;
            if (proxy && ![proxy isEqualToString:direct]) {
                printf("----- [pac:%s proxy:%s] -----",urlString.UTF8String,proxy.UTF8String);
                return YES;
            }
        }
    }
    return NO;
}
