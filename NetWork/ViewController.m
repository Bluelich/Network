//
//  ViewController.m
//  NetWork
//
//  Created by zhouqiang on 30/11/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import "ViewController.h"
#import "NetWorkStatusManager.h"
#import <CFNetwork/CFNetwork.h>
#import <CoreFoundation/CoreFoundation.h>
#import <sys/event.h>
#import <dns_sd.h>
#import <sys/ioctl.h>
#import "Interface.h"

@interface ViewController ()

@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    [NetWorkStatusManager shared];
    NSArray<Interface *> *all = [Interface allInterfaces];
    printf("");
    [all enumerateObjectsUsingBlock:^(Interface * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"");
    }];
    
//    kqueue();
//    CFNetServiceRef service = CFNetServiceCreate(kCFAllocatorDefault, (__bridge CFStringRef)@"https://www.meishubao.com", kCFStreamNetworkServiceType, (__bridge CFStringRef)@"name", 111);
//    CFNetServiceSetClient(service, NULL, NULL);
//    CFNetServiceScheduleWithRunLoop(service, CFRunLoopGetMain(), kCFRunLoopCommonModes);
//
//
//    NSNetService *service2 = [[NSNetService alloc] initWithDomain:@"local." type:@"_http._tcp." name:@"name"];
//    service2.delegate = self;
//    DNSServiceRef dns;
//    DNSServiceErrorType err = DNSServiceRegister(&dns, 0, 0, NULL, "_ftp._tcp", NULL, NULL, 80, 10, NULL, NULL, NULL);
//    DNSServiceSetDispatchQueue(dns, dispatch_get_global_queue(0, 0));
    
    
}
/**
 etnameinfo : getaddrinfo的逆操作 Thread safety

 @param addr    sockaddr(ipv4 or ipv6)
 @param addrlen size of addr
 @param host    char *
 @param hostlen size of host
 @param serv    char *
 @param servlen size of serv
 @param flags
     NI_NAMEREQD    如果hostname无法确定,会返回错误
     NI_DGRAM       服务是基于datagram(UDP)而不是基于stream(TCP)。对于UDP和TCP具有不同服务的几个端口(512–514),这是必需的。
     NI_NOFQDN      只返回本地host的的主机名部分。
     NI_NUMERICHOST 返回主机名的数字形式。(无法确定节点名称的情况下也会返回)
     NI_NUMERICSERV 返回服务地址的数字形式。(无法确定服务名称的情况下也会返回)
     NI_IDN         在查找过程中找到的名称将从IDN格式转换为区域设置编码(如有必要)。仅ASCII名称不受转换的影响,从而使此标志在现有程序和环境中可用。
     NI_IDN_ALLOW_UNASSIGNED     对应IDNA处理过程中的 IDNA_ALLOW_UNASSIGNED
     NI_IDN_USE_STD3_ASCII_RULES 对应IDNA处理过程中的 IDNA_USE_STD3_ASCII_RULES
 @return success: 0  failed: 1-15 (netdb.h)
 */
int getnameinfo(const struct sockaddr * __restrict addr, socklen_t addrlen,
                char * __restrict host, socklen_t hostlen,
                char * __restrict serv,socklen_t servlen,
                int flags);

void sockaddr_getInfo(struct sockaddr *sockaddr,char host[NI_MAXHOST],char service[NI_MAXSERV]){
    if (!sockaddr) {
        return;
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
        return;
    }
    int res = getnameinfo(sockaddr, socklen, host, NI_MAXHOST, service, NI_MAXSERV, flags);
    if (res != 0) {
        return;
    }
    printf("sockaddr_getInfo host=%s, service=%s\n", host, service);
}
- (void)getIP
{
    struct ifaddrs *ifaddr;
    //0:成功 -1:失败
    if (getifaddrs(&ifaddr) == -1) {
        perror("failed error:");
        return;
    }
    struct ifaddrs *ifaddr_tmp = ifaddr;
    
    while (ifaddr_tmp) {
        char *name = ifaddr_tmp->ifa_name;//接口名称
        unsigned int ifa_flags       = ifaddr_tmp->ifa_flags;
//        struct sockaddr *ifa_addr    = ifaddr_tmp->ifa_addr;
//        struct sockaddr *ifa_netmask = ifaddr_tmp->ifa_netmask;
//        struct sockaddr *ifa_dstaddr = ifaddr_tmp->ifa_dstaddr;
//        void *data = ifaddr_tmp->ifa_data;
        printf("name:%s\n",name);
        if (!(ifa_flags & IFF_UP)) {
            
        }
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
        char host[NI_MAXHOST];
        char service[NI_MAXSERV];
        sockaddr_getInfo(sockaddr, host, service);
        printf("");
    }
    freeifaddrs(ifaddr);
}
@end
