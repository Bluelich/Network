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

@interface ViewController ()<NSNetServiceDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [NetWorkStatusManager shared];
    [self getIP];
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
#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IOS_VPN         @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

- (NSString *)getIPAddress:(BOOL)preferIPv4 {
    NSArray *ipv4 = @[@"utun0/ipv4",
                      @"utun0/ipv6",
                      @"en0/ipv4",
                      @"en0/ipv6",
                      @"pdp_ip0/ipv4",
                      @"pdp_ip0/ipv6"];
    NSArray *ipv6 = @[@"utun0/ipv6",
                      @"utun0/ipv4",
                      @"en0/ipv6",
                      @"en0/ipv4",
                      @"pdp_ip0/ipv6",
                      @"pdp_ip0/ipv4"];
    NSArray *searchArray = preferIPv4 ? ipv4 : ipv6;
    /*
     {
         "awdl0/ipv6" = "fe80::4cdd:47ff:fece:a09b";
         "en0/ipv4" = "192.168.0.104";
         "lo0/ipv4" = "127.0.0.1";
         "lo0/ipv6" = "fe80::1";
         "utun0/ipv6" = "fe80::b2a2:92ba:e7b:d066";
         "utun1/ipv6" = "fe80::73cb:bb39:6f59:b631";
     }
     */
    NSDictionary *addresses = [self getIPAddresses];
    NSLog(@"addresses: %@", addresses);
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        address = addresses[key];
        if(address) *stop = YES;
    } ];
    return address ? address : @"0.0.0.0";
}
- (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = @"ipv4";
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = @"ipv6";
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

- (void)getIP
{
    /*
     struct ifaddrs {
        struct ifaddrs  *ifa_next;    // 链表的下一个对象
        char            *ifa_name;    // name
        unsigned int     ifa_flags;   // flags from SIOCGIFFLAGS
        struct sockaddr *ifa_addr;    // 地址
        struct sockaddr *ifa_netmask; // 子网掩码
        union {
            struct sockaddr *ifu_broadaddr;//广播地址(IFF_BROADCAST)
            struct sockaddr *ifu_dstaddr;  //点对点目标地址(IFF_POINTOPOINT)
        } ifa_ifu;
        void    *ifa_data;    //指向address-family-specific数据的缓冲区;此字段可能为NULL。
     };
     ifr_flags:
         IFF_UP            Interface is running.
         IFF_BROADCAST     Valid broadcast address set.
         IFF_DEBUG         Internal debugging flag.
         IFF_LOOPBACK      Interface is a loopback interface.
         IFF_POINTOPOINT   Interface is a point-to-point link.
         IFF_RUNNING       Resources allocated.
         IFF_NOARP         No arp protocol, L2 destination address not set.
         IFF_PROMISC       Interface is in 混合模式.
         IFF_NOTRAILERS    Avoid use of 追踪
         IFF_ALLMULTI      Receive all multicast packets.
         IFF_MASTER        Master of a load balancing bundle.
         IFF_SLAVE         Slave of a load balancing bundle.
         IFF_MULTICAST     Supports multicast
         IFF_PORTSEL       Is able to select media type via ifmap.
         IFF_AUTOMEDIA     Auto media selection active.
         IFF_DYNAMIC       The addresses are lost when the interface goes down.
         IFF_LOWER_UP      Driver signals L1 up (since Linux 2.6.17)
         IFF_DORMANT       Driver signals dormant (since Linux 2.6.17)
         IFF_ECHO          Echo sent packets (since Linux 2.6.25)
     */
    struct ifaddrs *ifaddr;
    //0:成功 -1:失败
    if (getifaddrs(&ifaddr) == -1) {
        perror("failed");
        return;
    }
    struct ifaddrs *ifaddr_tmp = ifaddr;
    char host[NI_MAXHOST],service[NI_MAXSERV];
    while (ifaddr_tmp) {
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
        if (getnameinfo(sockaddr, socklen, host, sizeof(host), service, sizeof(service), NI_NUMERICHOST|NI_NUMERICSERV|NI_NAMEREQD) != 0) {
            continue;
        }
        printf("host=%s, service=%s\n", host, service);
        
        /**
         getaddrinfo的逆操作 Thread safety
         flags:
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
        {
//            if(!(ifaddr_tmp->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
//                continue; // deeply nested code harder to read
//            }
        }
    }
    
    freeifaddrs(ifaddr);
}

@end
