//
//  Test.m
//  Network
//
//  Created by zhouqiang on 13/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import "Test.h"
#import <err.h>
#import <dns_sd.h>
#import <sys/event.h>

#if  TARGET_OS_OSX
static const void *NetworkConnectionRetainContextCallback(const void *info) {
    return Block_copy(info);
}
static void NetworkConnectionReleaseContextCallback(const void *info) {
    !info ?: Block_release(info);
}
static CFStringRef NetworkConnectionCopyDescriptionCallback(const void *info){
    return CFSTR("context desc");
}
void NetworkConnectionCallBack(SCNetworkConnectionRef connection,SCNetworkConnectionStatus status,void * __nullable info){
    
}
void test_connection(){
    void(^block)(SCNetworkConnectionRef connection,SCNetworkConnectionStatus status) = ^(SCNetworkConnectionRef connection,SCNetworkConnectionStatus status){
        SCNetworkConnectionStatus status2 = SCNetworkConnectionGetStatus(connection);
        switch (status2) {
            case kSCNetworkConnectionInvalid:
                break;
            case kSCNetworkConnectionConnecting:
                break;
            case kSCNetworkConnectionConnected:
                break;
            case kSCNetworkConnectionDisconnecting:
                break;
            case kSCNetworkConnectionDisconnected:
                break;
        }
    };
    CFIndex version = 0;
    void *info = (__bridge void *)block;
    SCNetworkConnectionCallBack callout = NetworkConnectionCallBack;
    SCNetworkConnectionContext context = {version,info,
                                          NetworkConnectionRetainContextCallback,
                                          NetworkConnectionReleaseContextCallback,
                                          NetworkConnectionCopyDescriptionCallback};
    SCNetworkConnectionRef connection = SCNetworkConnectionCreateWithServiceID(kCFAllocatorDefault, CFSTR("serviceID"), callout, &context);
    SCNetworkConnectionSetDispatchQueue(connection, dispatch_queue_create("", DISPATCH_QUEUE_SERIAL));
    SCNetworkConnectionScheduleWithRunLoop(connection, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    Boolean linger = true; //在闲置的时候不自动停止
    //https://developer.apple.com/library/content/documentation/Networking/Conceptual/SystemConfigFrameworks/SC_UnderstandSchema/SC_UnderstandSchema.html#//apple_ref/doc/uid/TP40001065-CH203-CHDFBDCB
    NSDictionary *options = @{@"UserDefinedName":@"e.g.ISP名称,将会显示在:偏好设置->网络->位置",
                              @"Network":@{@"Global":@{@"NetInfo":@"",
                                                       @"IPv4":@{@"ServiceOrder":@[],
                                                                 @"OverridePrimary":@"",
                                                                 @"PPPOverridePrimary":@""},},
                                           @"Interface":@{@"en0":@{@"Ethernet":@{@"Speed":@"",
                                                                                 @"duplex":@"",
                                                                                 @"MTU":@"",
                                                                                 @"__INACTIVE__":@""}}},//auto only
                                           @"Service":@{@"100":@{@"IPv4":@{@"ConfigMethod":@"BootP"},
                                                                 @"DNS":@{},
                                                                 @"Interface":@{@"DeviceName":@"en0",
                                                                                @"Hardware":@"Ethernet",
                                                                                @"Type":@"Ethernet",
                                                                                @"UserDefinedName":@"Built-in Ethernet"
                                                                                },
                                                                 @"UserDefinedName":@"Built-in Ethernet"}}}};
    SCNetworkConnectionStart(connection, (__bridge CFDictionaryRef)options, linger);
    options = (__bridge NSDictionary *)SCNetworkConnectionCopyUserOptions(connection);
    Boolean forceDisconnect = true;
    SCNetworkConnectionStop(connection, forceDisconnect);
    SCNetworkConnectionUnscheduleFromRunLoop(connection, CFRunLoopGetMain(), kCFRunLoopCommonModes);
}
#endif

/*
 The following code tries to connect to ``www.kame.net'' service ``http'' via a stream socket.
 It loops through all the addresses available, regardless of address family.
 If the destination resolves to an IPv4 address, it will use an PF_INET socket.
 Similarly, if it resolves to IPv6, an PF_INET6 socket is used.
 Observe that there is no hardcoded reference to a particular address family.
 The code works even if getaddrinfo() returns addresses that are not IPv4/v6.
 */
void test1(){
    struct addrinfo hints, *res, *res0;
    int error;
    int s;
    const char *cause = NULL;
    
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    error = getaddrinfo("www.kame.net", "http", &hints, &res0);
    if (error) {
        errx(1, "%s", gai_strerror(error));
        /*NOTREACHED*/
    }
    s = -1;
    for (res = res0; res; res = res->ai_next) {
        s = socket(res->ai_family, res->ai_socktype,
                   res->ai_protocol);
        if (s < 0) {
            cause = "socket";
            continue;
        }
        if (connect(s, res->ai_addr, res->ai_addrlen) < 0) {
            cause = "connect";
            close(s);
            s = -1;
            continue;
        }
        break;  /* okay we got one */
    }
    if (s < 0) {
        err(1, "%s", cause);
        /*NOTREACHED*/
    }
    freeaddrinfo(res0);
}
/*
 The following example tries to open a wildcard listening socket onto service ``http'', for all the address families available.
 https://opensource.apple.com/source/syslog/syslog-323.50.1/syslogd.tproj/udp_in.c.auto.html
 */
#define MAXSOCK 16
void test2(){
    struct addrinfo hints, *res, *res0;
    int error;
    int s[MAXSOCK];
    int nsock;
    const char *cause = NULL;
    
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;
    error = getaddrinfo(NULL, "http", &hints, &res0);
    if (error) {
        errx(1, "%s", gai_strerror(error));
        /*NOTREACHED*/
    }
    nsock = 0;
    for (res = res0; res && nsock < MAXSOCK; res = res->ai_next) {
        s[nsock] = socket(res->ai_family, res->ai_socktype,
                          res->ai_protocol);
        if (s[nsock] < 0) {
            cause = "socket";
            continue;
        }
        
        if (bind(s[nsock], res->ai_addr, res->ai_addrlen) < 0) {
            cause = "bind";
            close(s[nsock]);
            continue;
        }
        (void) listen(s[nsock], 5);
        
        nsock++;
    }
    if (nsock == 0) {
        err(1, "%s", cause);
        /*NOTREACHED*/
    }
    freeaddrinfo(res0);
}
const char* getIPV6(const char * mHost) {
    if(mHost == NULL)
        return NULL;
    struct addrinfo* res0;
    struct addrinfo hints;
    memset(&hints, 0, sizeof(hints));
    hints.ai_flags = AI_DEFAULT;
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    int n;
    if((n = getaddrinfo(mHost, "http", &hints, &res0)) != 0){
        printf("getaddrinfo failed %d", n);
        return NULL;
    }
    struct sockaddr_in6* addr6;
    struct sockaddr_in * addr;
    const char* pszTemp = NULL;
    struct addrinfo* res = res0;
    while (res) {
        char buf[32];
        if(res->ai_family == AF_INET6){
            addr6 = (struct sockaddr_in6*)res->ai_addr;
            pszTemp = inet_ntop(AF_INET6, &addr6->sin6_addr, buf, sizeof(buf));
        }else{
            addr = (struct sockaddr_in*)res->ai_addr;
            pszTemp = inet_ntop(AF_INET, &addr->sin_addr, buf, sizeof(buf));
        }
        res = res->ai_next;
    }
    freeaddrinfo(res0);
    printf("getaddrinfo ok %s\n", pszTemp);
    return pszTemp ?strdup(pszTemp) : NULL;
}
void getIP(){
    struct ifaddrs *ifaddr;
    //0:成功 -1:失败
    if (getifaddrs(&ifaddr) == -1) {
        perror("failed error:");
        return;
    }
    struct ifaddrs *ifaddr_tmp = ifaddr;
    
    while (ifaddr_tmp) {
        char *name = ifaddr_tmp->ifa_name;//接口名称
//        struct sockaddr *ifa_addr    = ifaddr_tmp->ifa_addr;
//        struct sockaddr *ifa_netmask = ifaddr_tmp->ifa_netmask;
//        struct sockaddr *ifa_dstaddr = ifaddr_tmp->ifa_dstaddr;
//        void *data = ifaddr_tmp->ifa_data;
        printf("\n\n\nname:%s\nflags:%s",name,NSStringFrom_if_flags(ifaddr_tmp->ifa_flags).UTF8String);
        struct sockaddr *sockaddr = ifaddr_tmp->ifa_addr;
        ifaddr_tmp = ifaddr_tmp->ifa_next;
        if (!sockaddr) {
            continue;
        }
        sa_family_t sa_family = sockaddr->sa_family;
        socklen_t socklen = 0;
        if (sa_family == AF_INET) {
            socklen = sizeof(struct sockaddr_in);
        }else if (sa_family == AF_INET6){
            socklen = sizeof(struct sockaddr_in6);
        }
        if (socklen == 0) {
            continue;
        }
        char *host;
        char *service;
        if (sockaddr_getInfo2(sockaddr, &host, &service)) {
            printf("\nhost: %s service:%s",host,service);
        }else{
            printf("\n get host and service err");
        }
    }
    freeifaddrs(ifaddr);
}

// 获取IPAddress
NSDictionary *getIPAddress(){
    NSMutableDictionary *addresses = @{}.mutableCopy;
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags &IFF_UP)/* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue;// deeply nested code is harder to read
            }
            const struct sockaddr *addr = (const struct sockaddr *)interface->ifa_addr;
            NSString *type =nil;
            void *addrptr = NULL;
            switch (addr->sa_family) {
                case AF_INET:
                {
                    struct in_addr sin_addr = ((const struct sockaddr_in *)addr)->sin_addr;
                    addrptr = &sin_addr;
                    type = @"IPv4";
                }
                    break;
                case AF_INET6:
                {
                    struct in6_addr sin_addr = ((const struct sockaddr_in6 *)addr)->sin6_addr;
                    addrptr = &sin_addr;
                    type = @"IPv6";
                }
                    break;
                default:
                    continue;
            }
            const char *addrBuf = inet_ntop(addr->sa_family, addrptr, malloc(INET6_ADDRSTRLEN), INET6_ADDRSTRLEN);
            NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
            NSString *key  = [NSString stringWithFormat:@"%@ %@", type,name];
            NSString *ip   = [NSString stringWithUTF8String:addrBuf];
            addresses[key] = ip;
        }
        freeifaddrs(interfaces);
    }
    return addresses.count ? addresses.copy : nil;
}

void test_other(){
    
}
void testMultipeerConnectivity(){
    
}
void test_sockaddr_storage(){
    struct addrinfo *hints, *res;
    getaddrinfo("www.kame.net", "http", hints, &res);
    __uint16_t udp_local_port = 0x1234;
    int usd = socket(AF_INET, SOCK_DGRAM, 0);
    struct sockaddr_storage local_addr;
    memset(&local_addr, 0, sizeof(struct sockaddr_storage));
    if(res->ai_family == AF_INET6) {
        struct sockaddr_in6 *local_addr6 = (struct sockaddr_in6 *)&local_addr;
        local_addr6->sin6_family = AF_INET6;
        local_addr6->sin6_port = htons(udp_local_port);
        local_addr6->sin6_addr = in6addr_any;
    }else if(res->ai_family == AF_INET){
        struct sockaddr_in *local_addr4 = (struct sockaddr_in *)&local_addr;
        local_addr4->sin_family = AF_INET;
        local_addr4->sin_port = htons(udp_local_port);
        local_addr4->sin_addr.s_addr = htonl(INADDR_ANY);
    }
    if(bind(usd,(struct sockaddr *)&local_addr,sizeof(local_addr)) == -1){
        perror("bind");
        fprintf(stderr,"could not bind to local udp port %d\n", udp_local_port);
        exit(1);
    }
    freeaddrinfo(res);
}

/**
 * Check for white-space characters
 */
bool is_space(unsigned int val){
    if (val == ' ' ||
        val == 0x00a0 ||
        val == 0x0085 ||
        val == 0x1680 ||
        val == 0x180e ||
        val == 0x2028 ||
        val == 0x2029 ||
        val == 0x202f ||
        val == 0x205f ||
        val == 0x3000) {
        return true;
    }else if (val <= 0x000d && val >= 0x0009){
        return true;
    }else if (val >= 0x2000 && val <= 0x200a){
        return true;
    }else{
        return false;
    }
}
bool sockaddr_getInfo2(struct sockaddr *sockaddr,char **host,char **service){
    if (!sockaddr) {
        return false;
    }
    int flags = 0;
    if (host) {
        flags |= NI_NUMERICHOST;
    }
    if (service) {
        flags |= NI_NUMERICSERV;
    }
    socklen_t socklen = 0;
    sa_family_t sa_family = sockaddr->sa_family;
    if (sa_family == AF_INET) {
        socklen = sizeof(struct sockaddr_in);
    }else if (sa_family == AF_INET6){
        socklen = sizeof(struct sockaddr_in6);
    }
    if (socklen == 0) {
        return false;
    }
    int res = getnameinfo(sockaddr, socklen, *host, NI_MAXHOST, *service, NI_MAXSERV, flags);
    return res == 0;
}

void socket_tcp_server_test(){
    int a = socket(1, 1, 1);
    setsockopt(1, 1, 1, "", 1);
    struct sockaddr addr;
    bind(1, &addr, 1);
    listen(1, 1);
    socklen_t x;
    accept(1, &addr, &x);
    /*
     MSG_DONTROUTE:主机在本地网络上面,不查找表,一般用网络诊断和路由程序
     MSG_OOB:接受或者发送带外数据
     MSG_PEEK:查看数据,并不从系统缓冲区移走数据
     MSG_WAITALL:等待所有数据
     */
    send(1, "aaa", 1, MSG_PEEK);
    recv(1, "", 1, MSG_WAITALL);
    read(1, "", 1);
    write(1, "", 1);
    close(a);
}
void socket_tcp_client_test(){
    socket(1, 1, 1);
    setsockopt(1, 1, 1, "", 1);
    struct sockaddr addr;
    bind(1, &addr, 1);
    connect(1, &addr, 1);
    send(1, "aaa", 1, 1);
    recv(1, "", 1, 1);
    read(1, "", 1);
    write(1, "", 1);
    close(1);
}
void socket_udp_server_test(){
    //不需要listen
    int a = socket(1, 1, 1);
    setsockopt(1, 1, 1, "", 1);
    struct sockaddr addr;
    bind(1, &addr, 1);
    socklen_t len;
    recvfrom(1, "", 1, 1, &addr, &len);
    sendto(1, "", 1, 1, &addr, len);
    close(a);
}
void socket_udp_client_test(){
    socket(1, 1, 1);
    setsockopt(1, 1, 1, "", 1);
    struct sockaddr addr;
    bind(1, &addr, 1);
    connect(1, &addr, 1);
    //如果调用了connect就直接可以用send和recv了,这时最后两个参数会自动用connect建立时的地址信息填充
    sendto(1, "", 1, 1, &addr, 1);
    socklen_t len;
    recvfrom(1, "", 1, 1, &addr, &len);
    close(1);
}


#pragma mark -
@implementation h_addr_list_obj
- (NSString *)description
{
    if (!self.host) {
        return nil;
    }
    return [NSString stringWithUTF8String:self.host];
}
@end

@implementation HostInfo
+ (instancetype)infoWithHost:(NSString *)hostName type:(int)type
{
    int length = 0;
    switch (type) {
        case AF_INET:
            length = INET_ADDRSTRLEN;
            break;
        case AF_INET6:
            length = INET6_ADDRSTRLEN;
            break;
        default:
            return nil;
    }
    HostInfo *obj = [HostInfo new];
    obj.sockaddr_length = length;
    obj.hostName = hostName;
    struct hostent *host = gethostbyname2(hostName.UTF8String, type);
    if (!host) {
        return obj;
    }
    NSMutableArray *h_addr_list = @[].mutableCopy;
    int h_addr_list_count = 0;
    while (host->h_addr_list[h_addr_list_count]) {
        void *addr = host->h_addr_list[h_addr_list_count];
        const char *ip = inet_ntop(type, addr, malloc(length), length);
        if (ip) {
            h_addr_list_obj *info = [h_addr_list_obj new];
            info.addr = addr;
            info.host = ip;
            [h_addr_list addObject:info];
        }
        h_addr_list_count++;
    }
    obj.h_addr_list = h_addr_list;
    obj.h_name = [NSString stringWithUTF8String:host->h_name];
    obj.h_addrtype = host->h_addrtype;
    obj.h_length = host->h_length;
    NSMutableArray *h_aliases = @[].mutableCopy;
    int h_aliases_count = 0;
    while (host->h_aliases[h_aliases_count]) {
        NSString *val = [NSString stringWithUTF8String:host->h_aliases[h_aliases_count]];
        [h_aliases addObject:val];
    }
    obj.h_aliases = h_aliases;
    return obj;
}
@end
long long doTask(void (^block)(void)){
    struct timeval time;
    int res = gettimeofday(&time, NULL);
    long long start = time.tv_sec * 1000000 + time.tv_usec;
    !block ?: block();
    if (res != 0) {
        printf("fetch task start time error : %d",res);
        switch (errno) {
            case EFAULT:
                printf("[EFAULT]  An argument address referenced invalid memory.");
                break;
            case EPERM:
                printf("[EPERM]   A user other than the super-user attempted to set the time.");
            default:
                break;
        }
        return 0;
    }
    res = gettimeofday(&time, NULL);
    if (res != 0) {
        printf("fetch task end time error : %d",res);
        switch (errno) {
            case EFAULT:
                printf("[EFAULT]  An argument address referenced invalid memory.");
                break;
            case EPERM:
                printf("[EPERM]   A user other than the super-user attempted to set the time.");
            default:
                break;
        }
        return 0;
    }
    long long end = time.tv_sec * 1000000 + time.tv_usec;
    long long duration = end - start;
    return duration;
}
void socket_connect(NSString *host){
    HostInfo *info = [HostInfo infoWithHost:host type:AF_INET];
    if (info.h_addr_list.count == 0) {
        printf("\nno ip respond to host :%s",info.hostName.UTF8String);
    }
    printf("\nlist:{\n%s\n}\n",info.h_addr_list.description.UTF8String);
    [info.h_addr_list enumerateObjectsUsingBlock:^(h_addr_list_obj * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        printf("\n*****************************\n");
        void *serv_addr = NULL;
        if (info.h_addrtype == AF_INET) {
            struct sockaddr_in addr_in;
            memset(&addr_in, 0, sizeof(struct sockaddr_in));
            addr_in.sin_port = htons(80);
            addr_in.sin_addr = *((struct in_addr *)(obj.addr));
            serv_addr = &addr_in;
        }else if (info.h_addrtype == AF_INET6){
            struct sockaddr_in6 addr_in6;
            memset(&addr_in6, 0, sizeof(struct sockaddr_in6));
            addr_in6.sin6_port = htons(80);
            addr_in6.sin6_addr = *((struct in6_addr *)(obj.addr));
            serv_addr = &addr_in6;
        }
        __block int retVal = -1;
        long long duration = doTask(^{
            int sockfd = socket(info.h_addrtype, SOCK_STREAM,0);
            if (sockfd < 0) {
                printf("socket error\n");
                return;
            }
            printf("\n[create] create a socket:%d",sockfd);
            printf("\nconnecting... ");
            retVal = connect(sockfd, serv_addr, info.sockaddr_length);
            if (retVal != 0) {
                printf("\nconnect failed");
                return;
            }
            printf("\n[connected]");
            NSData *data = [@"testData1" dataUsingEncoding:NSUTF8StringEncoding];
            printf("\n[send]    ");
            ssize_t size = send(sockfd, data.bytes, data.length, MSG_DONTROUTE);
            printf("%s",size > 0 ? "success" : "failed");
            
            struct iovec msg_iov = {
                .iov_base = (void *)data.bytes,
                .iov_len  = data.length
            };
//            struct cmsghdr msg_control = {
//                .cmsg_len = CMSG_LEN(3),
//                .cmsg_level = SOL_SOCKET,
//                .cmsg_type = SCM_TIMESTAMP,
//            };
            struct msghdr msg = {
                .msg_name = NULL,
                .msg_namelen = 1,
                .msg_iov = &msg_iov,
                .msg_iovlen = 1,
//                .msg_control = &msg_control,
//                .msg_controllen = sizeof(msg_control),
                .msg_flags = MSG_SEND
            };
            
            printf("\n[sendmsg] ");
            size = sendmsg(sockfd, &msg, 0);
            printf("%s",size > 0 ? "success" : "failed");
            
            printf("\n[sendto]  ");
            size = sendto(sockfd, data.bytes, data.length, MSG_DONTROUTE, serv_addr, info.sockaddr_length);
            printf("%s\n",size > 0 ? "success" : "failed");
        });
        printf("\nconnect:%s %s duration:%.3lf ms",obj.host,retVal == 0 ? "success":"failed", duration / 1000.f);
    }];
}

NSString *proxy_host(NSString *host){
    return [NSString stringWithFormat:@"%@:%@",host,NetworkHasAgentProxy([NSURL URLWithString:host]) ? @"YES" : @"NO"];
}
NSString *proxy_test(void){
    NSArray<NSString *> *urls = @[@"apple.com",
                      @"www.apple.com",
                      @"http://www.apple.com",
                      @"https://www.apple.com",
                      @"google.com",
                      @"www.google.com",
                      @"http://google.com",
                      @"https://google.com",
                      @"http://www.google.com",
                      @"https://www.google.com"];
    NSMutableArray<NSString *> *results = @[].mutableCopy;
    [urls enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [results addObject:proxy_host(obj)];
    }];
    return [results componentsJoinedByString:@"\n"];
}
#pragma mark -
@interface MyCFSocket : NSObject
@end
const void *socketRetain(const void *info){
    NSLog(@"%s",__PRETTY_FUNCTION__);
//    MyCFSocket *socketInfo = (__bridge MyCFSocket *)info;
//    return (void *)CFRetain((__bridge CFTypeRef)(socketInfo));
    return info;
}

void socketRelease(const void *info){
    NSLog(@"%s",__PRETTY_FUNCTION__);
//    MyCFSocket *socketInfo = (__bridge MyCFSocket *)info;
//    CFRelease((__bridge CFTypeRef)(socketInfo));
}
CFStringRef socketCopyDescription(const void *info){
    NSLog(@"%s",__PRETTY_FUNCTION__);
//    MyCFSocket *socketInfo = (__bridge MyCFSocket *)info;
//    return (__bridge CFStringRef)socketInfo.description;
    return CFSTR("[invoke socketCopyDescription]");
}
void readStreamClientCallBack(CFReadStreamRef stream, CFStreamEventType type, void *clientCallBackInfo){
    NSLog(@"%s",__PRETTY_FUNCTION__);
    uint8 buff[255];
    CFReadStreamRead(stream, buff, 255);
}
void writeStreamClientCallBack(CFWriteStreamRef stream, CFStreamEventType type, void *clientCallBackInfo){
    NSLog(@"%s",__PRETTY_FUNCTION__);
//    outputStream = stream;
}
void innerCFSocketCallBack(CFSocketRef socket, CFSocketCallBackType callBackType, CFDataRef addressData, const void *data, void *info){
    NSLog(@"%s",__PRETTY_FUNCTION__);
    //addressData: valid only for kCFSocketAcceptCallBack or kCFSocketDataCallBack
    MyCFSocket *socketInfo = (__bridge MyCFSocket *)info;
    if (![socketInfo isKindOfClass:MyCFSocket.class]) {
        return;
    }
    switch (callBackType) {
        case kCFSocketNoCallBack:break;
        case kCFSocketReadCallBack:break;
        case kCFSocketAcceptCallBack:break;
        case kCFSocketDataCallBack:break;
        case kCFSocketConnectCallBack:break;
        case kCFSocketWriteCallBack:break;
    }
    if (callBackType == kCFSocketAcceptCallBack) {
        CFSocketNativeHandle nativeSocketHandle = CFSocketGetNative(socket);
        struct sockaddr addr_remote;
        memset(&addr_remote, 0, sizeof(addr_remote));
        socklen_t addr_len = SOCK_MAXADDRLEN;
        if (getpeername(nativeSocketHandle, &addr_remote, &addr_len) != 0) {
            return;
        }
        struct in6_addr;
        if (addr_remote.sa_family == AF_INET) {
            struct sockaddr_in sockaddr_in = *(struct sockaddr_in *)&addr_remote;
            char ipaddr[INET_ADDRSTRLEN];
            inet_ntop(sockaddr_in.sin_family, (const void *)&(sockaddr_in.sin_addr), ipaddr, sizeof(ipaddr));
            printf("ipv4:%s",ipaddr);
        }else if (addr_remote.sa_family == AF_INET6){
            struct sockaddr_in6 sockaddr_in = *(struct sockaddr_in6 *)&addr_remote;
            char ipaddr[INET6_ADDRSTRLEN];
            inet_ntop(sockaddr_in.sin6_family, (const void *)&(sockaddr_in.sin6_addr), ipaddr, sizeof(ipaddr));
            printf("ipv6:%s",ipaddr);
        }else{
            return;
        }
        
        CFReadStreamRef  readStream;
        CFWriteStreamRef  writeStream;
        // 创建一个可读写的socket连接
        CFStreamCreatePairWithSocket(kCFAllocatorDefault,nativeSocketHandle,&readStream,&writeStream);
        if(readStream && writeStream){
            CFStreamClientContext streamContext = {
                .version = 0,
                .info = info,
                .retain = NULL,
                .release = NULL,
                .copyDescription = NULL
            };
            if(!CFReadStreamSetClient(readStream,kCFStreamEventHasBytesAvailable,readStreamClientCallBack,&streamContext)){
                return;
            }
            if(!CFWriteStreamSetClient(writeStream,kCFStreamEventCanAcceptBytes,writeStreamClientCallBack,&streamContext)){
                return;
            }
            NSString *buff = @"Hunter21,this is Overlord";
            CFWriteStreamWrite(writeStream,(const UInt8 *)buff.UTF8String,buff.length);
        }
    }
}
@implementation MyCFSocket
- (void)test
{
    CFSocketContext context = {
        .version = 0,
        .info = (__bridge void *)self,
        .retain = &socketRetain,
        .release = &socketRelease,
        .copyDescription = &socketCopyDescription
    };
    CFOptionFlags callBackTypes = kCFSocketReadCallBack | kCFSocketAcceptCallBack | kCFSocketDataCallBack | kCFSocketConnectCallBack | kCFSocketWriteCallBack;
    CFSocketCallBack callout = innerCFSocketCallBack;
    CFSocketRef socketRef = CFSocketCreate(kCFAllocatorDefault,
                                           PF_INET,    //ipv4:PF_INET    ipv6:PF_INET6
                                           SOCK_STREAM,//TCP:SOCK_STREAM UDP:SOCK_DGRAM
                                           IPPROTO_TCP,//TCP:IPPROTO_TCP UDP:IPPROTO_UDP
                                           callBackTypes,
                                           callout,
                                           &context);
    /*
     选项名称　　　　　　　　说明　　　　　　　　　　　　　　　　　　数据类型
     ========================================================================
     　　　　　　　　　　　    　SOL_SOCKET
     ------------------------------------------------------------------------
     SO_BROADCAST　　　　　　允许发送广播数据　　　　　　　　　　　　int
     SO_DEBUG　　　　　　　　允许调试　　　　　　　　　　　　　　　　int
     SO_DONTROUTE　　　　　　不查找路由　　　　　　　　　　　　　　　int
     SO_ERROR　　　　　　　　获得套接字错误　　　　　　　　　　　　　int
     SO_KEEPALIVE　　　　　　保持连接　　　　　　　　　　　　　　　　int
     SO_LINGER　　　　　　　 延迟关闭连接　　　　　　　　　　　　　　struct linger
     SO_OOBINLINE　　　　　　带外数据放入正常数据流　　　　　　　　　int
     SO_RCVBUF　　　　　　　 接收缓冲区大小　　　　　　　　　　　　　int
     SO_SNDBUF　　　　　　　 发送缓冲区大小　　　　　　　　　　　　　int
     SO_RCVLOWAT　　　　　　 接收缓冲区下限　　　　　　　　　　　　　int
     SO_SNDLOWAT　　　　　　 发送缓冲区下限　　　　　　　　　　　　　int
     SO_RCVTIMEO　　　　　　 接收超时　　　　　　　　　　　　　　　　struct timeval
     SO_SNDTIMEO　　　　　　 发送超时　　　　　　　　　　　　　　　　struct timeval
     SO_REUSERADDR　　　　　 允许重用本地地址和端口　　　　　　　　　int
     SO_TYPE　　　　　　　　 获得套接字类型　　　　　　　　　　　　　int
     SO_BSDCOMPAT　　　　　　与BSD系统兼容　　　　　　　　　　　　　 int
     ========================================================================
     　　　　　　　　　　　　IPPROTO_IP
     ------------------------------------------------------------------------
     IP_HDRINCL　　　　　　　在数据包中包含IP首部　　　　　　　　　　int
     IP_OPTINOS　　　　　　　IP首部选项　　　　　　　　　　　　　　　int
     IP_TOS　　　　　　　　　服务类型
     IP_TTL　　　　　　　　　生存时间　　　　　　　　　　　　　　　　int
     ========================================================================
     　　　　　　　　　　　　IPPRO_TCP
     ------------------------------------------------------------------------
     TCP_MAXSEG　　　　　　　TCP最大数据段的大小　　　　　　　　　　 int
     TCP_NODELAY　　　　　　 不使用Nagle算法　　　　　　　　　　　　 int
     ========================================================================
     */
    bool optval = true;
    CFSocketNativeHandle socket = CFSocketGetNative(socketRef);
    /*
     SOL_SOCKET:通用套接字选项
     IPPROTO_IP:IP选项
     IPPROTO_TCP:TCP选项
     */
    int level  = SOL_SOCKET;
    int option_name = SO_REUSEADDR;
    const void *option_value = (const void *)&(optval); //bool | 整形 | 结构体 (value of option_name)
    socklen_t option_len = sizeof(optval);
    int val = setsockopt(socket,level,option_name,option_value,option_len);
    if (val != 0) {
        NSLog(@"error:%d val is -1",errno);
        switch (errno) {
            case EBADF:
                NSLog(@"sock不是有效的文件描述词");
                break;
            case EFAULT:
                NSLog(@"optval指向的内存并非有效的进程空间");
                break;
            case EINVAL:
                NSLog(@"在调用setsockopt()时，optlen无效");
                break;
            case ENOPROTOOPT:
                NSLog(@"指定的协议层不能识别选项");
                break;
            case ENOTSOCK:
                NSLog(@"sock描述的不是套接字");
                break;
            default:
                break;
        }
    }
    
    struct sockaddr_in addr4_remote;
    memset(&addr4_remote , 0,sizeof(addr4_remote));
    addr4_remote.sin_len = sizeof(addr4_remote);
    addr4_remote.sin_family = AF_INET;
    addr4_remote.sin_port = htons(80);
    addr4_remote.sin_addr.s_addr = inet_addr("192.168.0.1");

//    // 定义本地监听地址以及端口
//    struct sockaddr_in addr4_local;
//    memset(&addr4_local, 0, sizeof(addr4_local));
//    addr4_local.sin_port = htons(80);
//    addr4_local.sin_addr.s_addr = htonl(INADDR_ANY);
//    CFDataRef addressRef_local = CFDataCreate(kCFAllocatorDefault,(const UInt8 *)&addr4_local,sizeof (addr4_local));
//    CFSocketError setAddressError = CFSocketSetAddress(socketRef ,addressRef_local);
//    if (setAddressError != kCFSocketSuccess) {
//        return;
//    }
    
    CFDataRef addressRef_remote = CFDataCreate(kCFAllocatorDefault,(const UInt8 *)&addr4_remote,sizeof (addr4_remote));
    if (CFSocketConnectToAddress(socketRef, addressRef_remote, 10) != kCFSocketSuccess) {
        return;
    }
    CFSocketCopyAddress(socketRef);
    CFSocketCopyPeerAddress(socketRef);
    CFRunLoopSourceRef socketSourceRef = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socketRef, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), socketSourceRef, kCFRunLoopCommonModes);
    CFRelease(socketSourceRef);
    CFDataRef data;
    CFSocketSendData(socketRef, CFSocketCopyAddress(socketRef), data, 10);
}
@end
void CFSocketTest(){
    [[MyCFSocket new] test];
}
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface Task ()
<
NSNetServiceDelegate,
MCNearbyServiceAdvertiserDelegate,
MCAdvertiserAssistantDelegate,
MCNearbyServiceBrowserDelegate,
MCBrowserViewControllerDelegate,
MCSessionDelegate
>
@property (nonatomic,strong) MCSession *session;
@end

@implementation Task
- (void)testNetService
{
    kqueue();
    CFNetServiceRef service = CFNetServiceCreate(kCFAllocatorDefault, (__bridge CFStringRef)@"https://www.baidu.com", kCFStreamNetworkServiceType, (__bridge CFStringRef)@"name", 111);
    CFNetServiceSetClient(service, NULL, NULL);
    CFNetServiceScheduleWithRunLoop(service, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    
    NSNetService *service2 = [[NSNetService alloc] initWithDomain:@"local." type:@"_http._tcp." name:@"name"];
    service2.delegate = self;
    DNSServiceRef dns;
    DNSServiceErrorType err = DNSServiceRegister(&dns, 0, 0, NULL, "_ftp._tcp", NULL, NULL, 80, 10, NULL, NULL, NULL);
    NSLog(@"%d",err);
    DNSServiceSetDispatchQueue(dns, dispatch_get_global_queue(0, 0));
}
- (void)testMultipeerConnectivity
{
    /*
     init session
     startAdvertisingPeer
     browser:foundPeer:withDiscoveryInfo:
     invitePeer:toSession:withContext:timeout
     advertiser:didReceiveInvitationFromPeer:withContext:invitationHandler:
     session:didReceiveCertificatte:fromPeer:
     session:peer:didChangeState:
     */
    MCPeerID *peerID = [[MCPeerID alloc] initWithDisplayName:@"displayName"];
    self.session = [[MCSession alloc] initWithPeer:peerID securityIdentity:@[] encryptionPreference:MCEncryptionNone];
    self.session.delegate = self;
    [self.session connectPeer:peerID withNearbyConnectionData:[NSData data]];
    NSError *error = nil;
    if (![self.session sendData:[NSData data] toPeers:@[peerID] withMode:MCSessionSendDataReliable error:&error]) {
        printf("error:%s",error.description.UTF8String);
        [self.session disconnect];
    }
    NSProgress *progress = [self.session sendResourceAtURL:[NSURL fileURLWithPath:@"a.txt"] withName:@"a text file" toPeer:peerID withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            printf("error:%s",error.description.UTF8String);
        }
    }];
    double pr = progress.completedUnitCount / (double)progress.totalUnitCount;
    printf("pr:%lf",pr);
    
    MCAdvertiserAssistant   *assistant = [[MCAdvertiserAssistant alloc] initWithServiceType:@"bluelich-test" discoveryInfo:@{@"key":@"value"} session:self.session];
    assistant.delegate = self;
    [assistant start];
    [assistant stop];
    MCNearbyServiceBrowser  *nsb = [[MCNearbyServiceBrowser alloc] initWithPeer:peerID serviceType:@"bluelich-test"];
    nsb.delegate = self;
    [nsb startBrowsingForPeers];
    [nsb stopBrowsingForPeers];
    MCBrowserViewController *vc = [[MCBrowserViewController alloc] initWithBrowser:nsb session:self.session];
    vc.delegate = self;
    
    MCNearbyServiceAdvertiser *nsa = [[MCNearbyServiceAdvertiser alloc] initWithPeer:peerID discoveryInfo:@{} serviceType:@"bluelich.-test"];
    nsa.delegate = self;
    [nsa startAdvertisingPeer];
    [nsa stopAdvertisingPeer];
}
#pragma mark - NSNetServiceDelegate
- (void)netServiceWillPublish:(NSNetService *)sender{}
- (void)netServiceDidPublish:(NSNetService *)sender{}
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary<NSString *, NSNumber *> *)errorDict{}
- (void)netServiceWillResolve:(NSNetService *)sender{}
- (void)netServiceDidResolveAddress:(NSNetService *)sender{}
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *, NSNumber *> *)errorDict{}
- (void)netServiceDidStop:(NSNetService *)sender{}
- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data{}
- (void)netService:(NSNetService *)sender didAcceptConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream{}
#pragma mark - MCNearbyServiceAdvertiserDelegate
- (void)            advertiser:(MCNearbyServiceAdvertiser *)advertiser
  didReceiveInvitationFromPeer:(MCPeerID *)peerID
                   withContext:(nullable NSData *)context
             invitationHandler:(void (^)(BOOL accept, MCSession * __nullable session))invitationHandler
{
    invitationHandler(YES,self.session);
}
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    printf("Advertising did not start due to an error:%s",error.description.UTF8String);
}
#pragma mark - MCAdvertiserAssistantDelegate
- (void)advertiserAssistantWillPresentInvitation:(MCAdvertiserAssistant *)advertiserAssistant{}
- (void)advertiserAssistantDidDismissInvitation:(MCAdvertiserAssistant *)advertiserAssistant{}
#pragma mark - MCNearbyServiceBrowserDelegate
- (void)        browser:(MCNearbyServiceBrowser *)browser
              foundPeer:(MCPeerID *)peerID
      withDiscoveryInfo:(nullable NSDictionary<NSString *, NSString *> *)info
{
    [browser invitePeer: peerID toSession:self.session withContext:nil timeout:30];
}
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    printf("A nearby peer has stopped advertising.");
}
- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    printf("Browsing did not start due to an error:%s",error.description.UTF8String);
}
#pragma mark - MCBrowserViewControllerDelegate
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{printf("Done button clicked");}
- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{printf("Cancel button clicked");}
- (BOOL)browserViewController:(MCBrowserViewController *)browserViewController
      shouldPresentNearbyPeer:(MCPeerID *)peerID
            withDiscoveryInfo:(nullable NSDictionary<NSString *, NSString *> *)info
{
    printf("if not implemented,every nearby peer will be presented to the user.");
    return YES;
}
#pragma mark - MCSessionDelegate
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    switch (state) {
        case MCSessionStateNotConnected: printf("NotConnected");
            break;
        case MCSessionStateConnecting: printf("Connecting");
            break;
        case MCSessionStateConnected: printf("Connected");
            break;
    }
}
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{}
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID{}
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{}
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(nullable NSURL *)localURL withError:(nullable NSError *)error{}
@end

