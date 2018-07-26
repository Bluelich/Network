//
//  Addr_Interface.m
//  Network
//
//  Created by zhouqiang on 14/12/2017.
//

#import "Addr_Interface.h"
#import <ifaddrs.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>

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
    switch (family) {
        case addr_sin_family_AF_UNSPEC:
            return @"AF_UNSPEC";
        case addr_sin_family_AF_UNIX | addr_sin_family_AF_LOCAL:
            return @"AF_UNIX | AF_LOCAL";
        case addr_sin_family_AF_INET:
            return @"AF_INET";
        case addr_sin_family_AF_IMPLINK:
            return @"AF_IMPLINK";
        case addr_sin_family_AF_PUP:
            return @"AF_PUP";
        case addr_sin_family_AF_CHAOS:
            return @"AF_CHAOS";
        case addr_sin_family_AF_NS:
            return @"AF_NS";
        case addr_sin_family_AF_ISO | addr_sin_family_AF_OSI:
            return @"AF_ISO |AF_OSI";
        case addr_sin_family_AF_ECMA:
            return @"AF_ECMA";
        case addr_sin_family_AF_DATAKIT:
            return @"AF_DATAKIT";
        case addr_sin_family_AF_CCITT:
            return @"AF_CCITT";
        case addr_sin_family_AF_SNA:
            return @"AF_SNA";
        case addr_sin_family_AF_DECnet:
            return @"AF_DECnet";
        case addr_sin_family_AF_DLI:
            return @"AF_DLI";
        case addr_sin_family_AF_LAT:
            return @"AF_LAT";
        case addr_sin_family_AF_HYLINK:
            return @"AF_HYLINK";
        case addr_sin_family_AF_APPLETALK:
            return @"AF_APPLETALK";
        case addr_sin_family_AF_ROUTE:
            return @"AF_ROUTE";
        case addr_sin_family_AF_LINK:
            return @"AF_LINK";
        case addr_sin_family_pseudo_AF_XTP:
            return @"pseudo_AF_XTP";
        case addr_sin_family_AF_COIP:
            return @"AF_COIP";
        case addr_sin_family_AF_CNT:
            return @"AF_CNT";
        case addr_sin_family_pseudo_AF_RTIP:
            return @"pseudo_AF_RTIP";
        case addr_sin_family_AF_IPX:
            return @"AF_IPX";
        case addr_sin_family_AF_SIP:
            return @"AF_SIP";
        case addr_sin_family_pseudo_AF_PIP:
            return @"pseudo_AF_PIP";
        case addr_sin_family_AF_NDRV:
            return @"AF_NDRV";
        case addr_sin_family_AF_ISDN | addr_sin_family_AF_E164:
            return @"AF_ISDN | AF_E164";
        case addr_sin_family_pseudo_AF_KEY:
            return @"pseudo_AF_KEY";
        case addr_sin_family_AF_INET6:
            return @"AF_INET6";
        case addr_sin_family_AF_NATM:
            return @"AF_NATM";
        case addr_sin_family_AF_SYSTEM:
            return @"AF_SYSTEM";
        case addr_sin_family_AF_NETBIOS:
            return @"AF_NETBIOS";
        case addr_sin_family_AF_PPP:
            return @"AF_PPP";
        case addr_sin_family_pseudo_AF_HDRCMPLT:
            return @"pseudo_AF_HDRCMPLT";
        case addr_sin_family_AF_RESERVED_36:
            return @"AF_RESERVED_36";
        case addr_sin_family_AF_IEEE80211:
            return @"AF_IEEE80211";
        case addr_sin_family_AF_UTUN:
            return @"AF_UTUN";
        case addr_sin_family_AF_MAX:
            return @"AF_MAX";
    }
}
NSArray<NSString *> *getInterfaceNames(void);
@interface Addr_Interface ()

@property (nonatomic,assign) if_flags         flags;
@property (nonatomic,assign) addr_sin_family  family;
@property (nonatomic,  copy) NSString  *name;
@property (nonatomic,  copy) NSString  *addr;
@property (nonatomic,  copy) NSString  *netmask;
@property (nonatomic,  copy) NSString  *dstaddr;
@property (nonatomic,strong) NSData    *data;
@property (nonatomic) Address_format     address_format;

@property (nonatomic) if_flags           ifa_flags;/**< flags */
@property (nonatomic) char              *ifa_name;/**< 接口名称 */
@property (nonatomic) struct sockaddr   *ifa_addr;/**< 地址 */
@property (nonatomic) struct sockaddr   *ifa_netmask;/**< 子网掩码 */
@property (nonatomic) struct sockaddr   *ifa_dstaddr;/**< 点对点目标地址(IFF_POINTOPOINT) */
@property (nonatomic) void              *ifa_data;/**< ifa_data存储了该接口协议族的特殊信息，它通常是NULL */

@end

@implementation Addr_Interface
- (BOOL)isValid
{
    BOOL valid = (self.ifa_flags & IFF_UP       ) &&
                 (self.ifa_flags & IFF_RUNNING  ) &&
                 (self.ifa_flags & IFF_MULTICAST);
    return valid;
}
+ (NSArray<NSString *> *)allInterfaceNames
{
    return getInterfaceNames();
}
+ (NSArray<Addr_Interface *> *)allInterfaces
{
    struct ifaddrs *ifaddr;
    //0:成功 -1:失败
    if (getifaddrs(&ifaddr) == -1) {
        perror("failed error:");
        return nil;
    }
    struct ifaddrs *ifaddr_tmp = ifaddr;
    NSMutableArray<Addr_Interface *> *interfaces = [NSMutableArray array];
    while (ifaddr_tmp) {
        Addr_Interface *interface = [[Addr_Interface alloc] init];
        interface.ifa_flags   = ifaddr_tmp->ifa_flags;
        interface.ifa_name    = ifaddr_tmp->ifa_name;
        interface.ifa_addr    = ifaddr_tmp->ifa_addr;
        interface.ifa_netmask = ifaddr_tmp->ifa_netmask;
        interface.ifa_dstaddr = ifaddr_tmp->ifa_dstaddr;
        interface.ifa_data    = ifaddr_tmp->ifa_data;
        [interface parser];
        [interfaces addObject:interface];
        printf("\n\n\n[flag]:%s",NSStringFrom_if_flags(interface.ifa_flags).description.UTF8String);
        sockaddr_desc(interface.ifa_addr,    "ifa_addr");
        sockaddr_desc(interface.ifa_netmask, "ifa_netmask");
        sockaddr_desc(interface.ifa_dstaddr, "ifa_dstaddr");
        printf("\n");
        ifaddr_tmp = ifaddr_tmp->ifa_next;
    }
    freeifaddrs(ifaddr);
    return interfaces;
}
- (void)parser
{
    /*
     Two character prefixes based on the type of interface:
     en -- ethernet
     sl -- serial line IP (slip)
     wl -- wlan
     ww -- wwan
     */
    self.name = [NSString stringWithUTF8String:self.ifa_name];
    self.flags = self.ifa_flags;
    self.family = self.ifa_addr->sa_family;
    socklen_t len = 0;
    const void *addr;
    switch (self.ifa_addr->sa_family) {
        case addr_sin_family_AF_INET:
        {
            self.address_format = Address_format_ipv4;
            len = INET_ADDRSTRLEN;
            struct sockaddr_in addr_ipv4 = *(struct sockaddr_in *)self.ifa_addr;
            addr =  &addr_ipv4.sin_addr;
        }
            break;
        case addr_sin_family_AF_INET6:
        {
            self.address_format = Address_format_ipv6;
            len = INET6_ADDRSTRLEN;
            struct sockaddr_in6 addr_ipv6 = *(struct sockaddr_in6 *)self.ifa_addr;
            addr =  &addr_ipv6.sin6_addr;
        }
            break;
        default:
            self.address_format = Address_format_other;
            return;
    }
    char addr_buf[len];
    const char *ptr = inet_ntop(self.ifa_addr->sa_family, addr, addr_buf, len);
    printf("%p",ptr);
    self.addr = [NSString stringWithUTF8String:addr_buf];
}
@end
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
