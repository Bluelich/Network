//
//  ReachabilityDefination.m
//  Network
//
//  Created by zhouqiang on 14/12/2017.
//

#import "ReachabilityDefination.h"

void __releaseCFObject__(CFTypeRef cf){ if (!cf) return; CFRelease(cf);}
BOOL ConnectedToInternet(Address_format prefer_format){
    BOOL ipv6 = prefer_format & Address_format_ipv6;
    if (!ipv6) {
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
    __releaseCFObject__(defaultRouteReachability);
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
/*
 * 判断当前网络状态下,是否有HTTP/HTTPS代理
 */
BOOL NetworkHasAgentProxy(){
    CFStringRef domain = CFStringCreateWithCString(kCFAllocatorDefault, "http://www.apple.com", kCFStringEncodingUTF8);
    CFURLRef url = CFURLCreateWithString(kCFAllocatorDefault, domain, NULL);
    __releaseCFObject__(domain);
    CFArrayRef proxies = CFNetworkCopyProxiesForURL(url,CFNetworkCopySystemProxySettings());
    __releaseCFObject__(url);
    CFIndex count = CFArrayGetCount(proxies);
    BOOL result = NO;
    for (CFIndex idx = 0; idx < count; idx++) {
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
            result = YES;
        }else{
            CFStringRef host = CFDictionaryGetValue(proxy, kCFProxyHostNameKey);
            CFStringRef port = CFDictionaryGetValue(proxy, kCFProxyPortNumberKey);
            if (host != NULL || port != NULL){
                result = YES;
            }
            __releaseCFObject__(host);
            __releaseCFObject__(port);
        }
        __releaseCFObject__(proxy);
        __releaseCFObject__(type);
    }
    __releaseCFObject__(proxies);
    return result;
}
