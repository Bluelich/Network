//
//  ReachabilityDefination.m
//  Network
//
//  Created by zhouqiang on 14/12/2017.
//

#import "ReachabilityDefination.h"

struct sockaddr_desc {
    __uint8_t    sa_len;     //总长度
    sa_family_t  sa_family;  //addr_sin_family
    //协议地址，由sa_family决定。
    char         sa_data[14];// sin_port(2) + sin_addr(4) + sin_zero(8)
};
struct sockaddr_in_desc {
    __uint8_t      sin_len;   //8-bit -> 1 Byte
    sa_family_t    sin_family;//8-bit -> 1 Byte
    in_port_t      sin_port;  //端口号（使用网络字节顺序）    16-bit -> 2 Byte
    struct in_addr sin_addr;  //ip地址 (按照网络字节顺序存储) 32-bit -> 4 Byte
    char           sin_zero[8];//空字节,用来填充到与struct sockaddr同样的长度，以支持互相转换
};
/*
 ipv6 报头
 
 0~31    版本号(6) + Qos(流量等级) + 流标签(标识同一个流里面的报文)
 32~63   载荷长度 +下一报头　＋　跳数限制
 64~191  源地址
 192~320 目标地址
 
 流标签
 RFC2460对IPv6流标签的特征进行了说明：
 (1) 一个流由源地址和流标签的组合唯一确定。 一对源和目的之间有可能有多个激活的流，也可能有不属于任何一个流的流量
 (2) 所携带的流标签值为 0 的数据包不属于任何一个流。
 (3)需要发送流的源节点赋给其流标签特定的值。流标签是一个随机数，目的是使所产生的流标签都能作为哈希关键字。
 对那些不支持流标签处理的设备节点和应用把流标签值赋值为 0，或者不对该字段处理。
 (4)一个流那些的所有数据包产生时必须具有相同的属性，包括源地址、目的地址、非 0 的流标签。
 (5)如果其中任何一个数据包包含逐跳选项报头，那么流的每一个包都必须包含相同的逐跳选项报头(逐跳选项报头的下一个报头字段除外)。
 (6)流路径中流处理状态的最大生命周期要在状态建立机制中说明。
 (7)当一个结点重启时，例如死机后的恢复运行，必须小心使用流标签，因为该流标签有可能在前面仍处于最大生存周期内的的流中使用。
 (8)不要求所有或至少大多数数据包属于某一个流，即都携带有非 0 的流标签
 
 sin6_scope_id:网口标识
 e.g. fe80::xxxx:xxxx:xxxx:xxxx%4 -> (<address>%<zone index>)
 */
//28 byte != 16 Byte(大小不一致问题应该是系统内部有处理)
struct sockaddr_in6_desc {
    __uint8_t    sin6_len;       //IPv6 为固定的24 字节长度   8-bit -> 1 Byte
    sa_family_t    sin6_family;  //地址簇类型，为AF_INET6     8-bit -> 1 Byte
    in_port_t    sin6_port;      //16 位端口号，网络字节序    16-bit -> 2 Byte
    __uint32_t    sin6_flowinfo; //32 位流标签              32-bit -> 4 Byte
    struct in6_addr    sin6_addr;//128 位IP 地址           128-bit -> 16 Byte
    __uint32_t    sin6_scope_id; //地址所在的接口索引         32-bit -> 4 Byte
};
//新的结构体 struct sockaddr_storage对IPv6有更好的支持
//而不需要让开发者传递一个28byte的结构体指针给一个16byte的结构体指针(28->16因为是指针,只要内部处理了,就不会有问题)
struct sockaddr_storage_desc {
    __uint8_t    ss_len;        /* address length */
    sa_family_t    ss_family;    /* [XSI] address family */
    char            __ss_pad1[_SS_PAD1SIZE];
    __int64_t    __ss_align;    /* force structure storage alignment */
    char            __ss_pad2[_SS_PAD2SIZE];
};

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
        struct sockaddr_in6_desc address_6;
        bzero(&address_6, sizeof(struct sockaddr_in6_desc));
        address_6.sin6_len = sizeof(struct sockaddr_in6_desc);
        address_6.sin6_family = AF_INET6;
        address = (struct sockaddr *)&address_6;
    }else{
        struct sockaddr_in_desc address_4;
        bzero(&address_4, sizeof(struct sockaddr_in_desc));//置0同memset
        address_4.sin_len = sizeof(struct sockaddr_in_desc);
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
