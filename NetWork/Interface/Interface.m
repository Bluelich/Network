//
//  Interface.m
//  NetWork
//
//  Created by zhouqiang on 12/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import "Interface.h"

NSString *NSStringFrom_if_flags(if_flags flags){
    NSMutableArray *array = [NSMutableArray array];
    if (flags & if_flags_IFF_UP) {
        [array addObject:@"IFF_UP"];
    }
    if (flags & if_flags_IFF_BROADCAST) {
        [array addObject:@"IFF_BROADCAST"];
    }
    if (flags & if_flags_IFF_DEBUG) {
        [array addObject:@"IFF_DEBUG"];
    }
    if (flags & if_flags_IFF_LOOPBACK) {
        [array addObject:@"IFF_LOOPBACK"];
    }
    if (flags & if_flags_IFF_POINTOPOINT) {
        [array addObject:@"IFF_POINTOPOINT"];
    }if (flags & if_flags_IFF_NOTRAILERS) {
        [array addObject:@"IFF_NOTRAILERS"];
    }
    if (flags & if_flags_IFF_RUNNING) {
        [array addObject:@"IFF_RUNNING"];
    }
    if (flags & if_flags_IFF_NOARP) {
        [array addObject:@"IFF_NOARP"];
    }
    if (flags & if_flags_IFF_PROMISC) {
        [array addObject:@"IFF_PROMISC"];
    }
    if (flags & if_flags_IFF_ALLMULTI) {
        [array addObject:@"IFF_ALLMULTI"];
    }
    if (flags & if_flags_IFF_OACTIVE) {
        [array addObject:@"IFF_OACTIVE"];
    }
    if (flags & if_flags_IFF_SIMPLEX) {
        [array addObject:@"IFF_SIMPLEX"];
    }
    if (flags & if_flags_IFF_LINK0) {
        [array addObject:@"IFF_LINK0"];
    }
    if (flags & if_flags_IFF_LINK1) {
        [array addObject:@"IFF_LINK1"];
    }
    if (flags & if_flags_IFF_LINK2) {
        [array addObject:@"IFF_LINK2"];
    }
    if (flags & if_flags_IFF_ALTPHYS) {
        [array addObject:@"IFF_ALTPHYS"];
    }
    if (flags & if_flags_IFF_MULTICAST) {
        [array addObject:@"IFF_MULTICAST"];
    }
    return [array componentsJoinedByString:@" | "];
}
NSString *NSStringFrom_addr_sin_family(addr_sin_family family){
    return @"";
}
NSArray<NSString *> *getInterfaceNames(){
    struct if_nameindex *if_ni = if_nameindex();
    if (if_ni == NULL) {
        perror("if_nameindex");
        return nil;
    }
    NSMutableArray<NSDictionary *> *array = [NSMutableArray array];
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    struct if_nameindex *i = if_ni;
    do {
        unsigned int if_index = i->if_index;
        char *name = i->if_name;
        if (if_index == 0 && name == NULL) {
            break;
        }
        [array addObject:@{@"index":@(if_index),
                           @"name" :[NSString stringWithUTF8String:name]}];
        [names addObject:@""];
        i++;
    } while (YES);
    
    [array enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull dic, NSUInteger idx, BOOL * _Nonnull stop) {
        [names replaceObjectAtIndex:[dic[@"index"] unsignedIntegerValue] - 1 withObject:dic[@"name"] ];
    }];
    return names.copy;
}
void sockaddr_desc(struct sockaddr *sockaddr,const char *name){
    if (!sockaddr) {
        printf("\n[%s] NULL",name);
        return;
    }
    char        *sa_data    = sockaddr->sa_data;
    __uint8_t   sa_len      = sockaddr->sa_len;
    sa_family_t sa_family   = sockaddr->sa_family;
    printf("\n[%s] sa_data:%s sa_len:%uc sa_family:%s",
           name,sa_data,sa_len,NSStringFrom_if_flags(sa_family).description.UTF8String);
}

#import <ifaddrs.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>

@interface Interface ()

@property (nonatomic,assign) if_flags         flags;  /**< flags */
@property (nonatomic,assign) addr_sin_family  family;
@property (nonatomic,  copy) NSString  *name;   /**< 接口名称 */
@property (nonatomic,  copy) NSString  *addr;   /**< 地址 */
@property (nonatomic,  copy) NSString  *netmask;/**< 子网掩码 */
@property (nonatomic,  copy) NSString  *dstaddr;/**< 点对点目标地址(IFF_POINTOPOINT) */
@property (nonatomic,strong) NSData    *data;   /**< ifa_data存储了该接口协议族的特殊信息，它通常是NULL */
@property (nonatomic) Address_format     address_format;

@property (nonatomic) if_flags           ifa_flags;
@property (nonatomic) char              *ifa_name;
@property (nonatomic) struct sockaddr   *ifa_addr;
@property (nonatomic) struct sockaddr   *ifa_netmask;
@property (nonatomic) struct sockaddr   *ifa_dstaddr;
@property (nonatomic) void              *ifa_data;

@end

@implementation Interface
+ (NSArray<NSString *> *)allInterfaceNames
{
    return getInterfaceNames();
}
//bool valid = (ifa_flags & IFF_UP       ) &&
//             (ifa_flags & IFF_RUNNING  ) &&
//             (ifa_flags & IFF_MULTICAST);
//if (!valid) {
//    ifaddr_tmp = ifaddr_tmp->ifa_next;
//    continue;
//}
+ (NSArray<Interface *> *)allInterfaces
{
    struct ifaddrs *ifaddr;
    //0:成功 -1:失败
    if (getifaddrs(&ifaddr) == -1) {
        perror("failed error:");
        return nil;
    }
    struct ifaddrs *ifaddr_tmp = ifaddr;
    NSMutableArray<Interface *> *interfaces = [NSMutableArray array];
    while (ifaddr_tmp) {
        Interface *interface = [[Interface alloc] init];
        interface.ifa_flags   = ifaddr_tmp->ifa_flags;
        interface.ifa_name    = ifaddr_tmp->ifa_name;
        interface.ifa_addr    = ifaddr_tmp->ifa_addr;
        interface.ifa_netmask = ifaddr_tmp->ifa_netmask;
        interface.ifa_dstaddr = ifaddr_tmp->ifa_dstaddr;
        interface.ifa_data    = ifaddr_tmp->ifa_data;
        [interface parser];
        [interfaces addObject:interface];
//        printf("\nflag:%s",NSStringFrom_if_flags(interface.ifa_flags).description.UTF8String);
//        sockaddr_desc(interface.ifa_addr,    "ifa_addr");
//        sockaddr_desc(interface.ifa_netmask, "ifa_netmask");
//        sockaddr_desc(interface.ifa_dstaddr, "ifa_dstaddr");
        ifaddr_tmp = ifaddr_tmp->ifa_next;
    }
    freeifaddrs(ifaddr);
    return interfaces;
}
- (void)parser
{
    self.name = [NSString stringWithUTF8String:self.ifa_name];
    self.flags = self.ifa_flags;
    self.family = self.ifa_addr->sa_family;
    socklen_t len = 0;
    const void *addr;
    switch (self.ifa_addr->sa_family) {
        case AF_INET:
        {
            self.address_format = Address_format_ipv4;
            len = INET_ADDRSTRLEN;
            struct sockaddr_in *addr_ipv4 = (struct sockaddr_in *)self.ifa_addr;
            addr =  &addr_ipv4->sin_addr;
        }
            break;
        case AF_INET6:
        {
            self.address_format = Address_format_ipv6;
            len = INET6_ADDRSTRLEN;
            struct sockaddr_in6 *addr_ipv6 = (struct sockaddr_in6 *)self.ifa_addr;
            addr =  &addr_ipv6->sin6_addr;
        }
            break;
        default:
            self.address_format = Address_format_other;
            break;
    }
    if (len) {
        char addr_buf[len];
        inet_ntop(self.ifa_addr->sa_family, addr, addr_buf, len);
        self.addr = [NSString stringWithUTF8String:addr_buf];
    }
}
@end
