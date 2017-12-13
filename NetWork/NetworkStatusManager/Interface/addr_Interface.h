//
//  Addr_Interface.h
//  NetWork
//
//  Created by zhouqiang on 12/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <net/if.h>
#import <netdb.h>

typedef NS_OPTIONS(NSUInteger, if_flags) {
    ///interface is up
    if_flags_IFF_UP              = IFF_UP,
    ///broadcast address valid
    if_flags_IFF_BROADCAST       = IFF_BROADCAST,
    ///turn on debugging
    if_flags_IFF_DEBUG           = IFF_DEBUG,
    ///is a loopback net
    if_flags_IFF_LOOPBACK        = IFF_LOOPBACK,
    ///interface is point-to-point link
    if_flags_IFF_POINTOPOINT     = IFF_POINTOPOINT,
    ///obsolete: avoid use of trailers
    if_flags_IFF_NOTRAILERS      = IFF_NOTRAILERS,
    //resources allocated
    if_flags_IFF_RUNNING         = IFF_RUNNING,
    ///no address resolution protocol
    if_flags_IFF_NOARP           = IFF_NOARP,
    ///receive all packets
    if_flags_IFF_PROMISC         = IFF_PROMISC,
    ///receive all multicast packets
    if_flags_IFF_ALLMULTI        = IFF_ALLMULTI,
    ///transmission in progress
    if_flags_IFF_OACTIVE         = IFF_OACTIVE,
    ///can't hear own transmissions
    if_flags_IFF_SIMPLEX         = IFF_SIMPLEX,
    ///per link layer defined bit
    if_flags_IFF_LINK0           = IFF_LINK0,
    ///per link layer defined bit
    if_flags_IFF_LINK1           = IFF_LINK1,
    ///per link layer defined bit
    if_flags_IFF_LINK2           = IFF_LINK2,
    ///use alternate physical connection
    if_flags_IFF_ALTPHYS         = IFF_ALTPHYS,
    ///supports multicast
    if_flags_IFF_MULTICAST       = IFF_MULTICAST,
};

typedef NS_ENUM(NSUInteger, addr_sin_family) {
    ///unspecified
    addr_sin_family_AF_UNSPEC           = AF_UNSPEC,
    ///local to host (pipes)
    addr_sin_family_AF_UNIX             = AF_UNIX,
#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)
    ///backward compatibility
    addr_sin_family_AF_LOCAL            = AF_LOCAL,
#endif
    ///internetwork: UDP, TCP, etc.
    addr_sin_family_AF_INET             = AF_INET,
#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)
    ///arpanet imp addresses
    addr_sin_family_AF_IMPLINK          = AF_IMPLINK,
    ///pup protocols: e.g. BSP
    addr_sin_family_AF_PUP              = AF_PUP,
    ///mit CHAOS protocols
    addr_sin_family_AF_CHAOS            = AF_CHAOS,
    ///XEROX NS protocols
    addr_sin_family_AF_NS               = AF_NS,
    ///ISO protocols
    addr_sin_family_AF_ISO              = AF_ISO,
    ///
    addr_sin_family_AF_OSI              = AF_OSI,
    ///European computer manufacturers
    addr_sin_family_AF_ECMA             = AF_ECMA,
    ///datakit protocols
    addr_sin_family_AF_DATAKIT          = AF_DATAKIT,
    ///CCITT protocols, X.25 etc
    addr_sin_family_AF_CCITT            = AF_CCITT,
    ///IBM SNA
    addr_sin_family_AF_SNA              = AF_SNA,
    ///DECnet
    addr_sin_family_AF_DECnet           = AF_DECnet,
    ///DEC Direct data link interface
    addr_sin_family_AF_DLI              = AF_DLI,
    ///LAT
    addr_sin_family_AF_LAT              = AF_LAT,
    ///NSC Hyperchannel
    addr_sin_family_AF_HYLINK           = AF_HYLINK,
    ///Apple Talk
    addr_sin_family_AF_APPLETALK        = AF_APPLETALK,
    ///Internal Routing Protocol
    addr_sin_family_AF_ROUTE            = AF_ROUTE,
    ///Link layer interface
    addr_sin_family_AF_LINK             = AF_LINK ,
    ///eXpress Transfer Protocol (no AF)
    addr_sin_family_pseudo_AF_XTP       = pseudo_AF_XTP,
    ///eXpress Transfer Protocol (no AF)
    addr_sin_family_AF_COIP             = AF_COIP,
    ///Computer Network Technology
    addr_sin_family_AF_CNT              = AF_CNT,
    ///Help Identify RTIP packets
    addr_sin_family_pseudo_AF_RTIP      = pseudo_AF_RTIP,
    //Novell Internet Protocol
    addr_sin_family_AF_IPX              = AF_IPX,
    ///Simple Internet Protocol
    addr_sin_family_AF_SIP              = AF_SIP,
    ///Help Identify PIP packets
    addr_sin_family_pseudo_AF_PIP       = pseudo_AF_PIP,
    ///Network Driver 'raw' access
    addr_sin_family_AF_NDRV             = AF_NDRV,
    ///Integrated Services Digital Network
    addr_sin_family_AF_ISDN             = AF_ISDN ,
    ///CCITT E.164 recommendation
    addr_sin_family_AF_E164             = AF_E164,
    ///Internal key-management function
    addr_sin_family_pseudo_AF_KEY       = pseudo_AF_KEY,
#endif
    ///IPv6
    addr_sin_family_AF_INET6            = AF_INET6,
#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)
    ///native ATM access
    addr_sin_family_AF_NATM             = AF_NATM,
    ///Kernel event messages
    addr_sin_family_AF_SYSTEM           = AF_SYSTEM,
    ///NetBIOS
    addr_sin_family_AF_NETBIOS          = AF_NETBIOS,
    ///PPP communication protocol
    addr_sin_family_AF_PPP              = AF_PPP,
    ///Used by BPF to not rewrite headers in interface output routine
    addr_sin_family_pseudo_AF_HDRCMPLT  = pseudo_AF_HDRCMPLT,
    ///Reserved for internal usage
    addr_sin_family_AF_RESERVED_36      = AF_RESERVED_36,
    ///IEEE 802.11 protocol
    addr_sin_family_AF_IEEE80211        = AF_IEEE80211,
    ///
    addr_sin_family_AF_UTUN             = AF_UTUN,
    ///
    addr_sin_family_AF_MAX              = AF_MAX,
#endif
};
typedef NS_ENUM(NSUInteger, Address_format) {
    Address_format_other  = 0,
    Address_format_ipv4   = AF_INET,
    Address_format_ipv6   = AF_INET6,
};

FOUNDATION_EXPORT NSString *NSStringFrom_if_flags(if_flags flags);
FOUNDATION_EXPORT NSString *NSStringFrom_addr_sin_family(addr_sin_family family);

@interface Addr_Interface : NSObject

@property (nonatomic,assign,getter=isValid,readonly)BOOL valid;
@property (class,nonatomic,strong,readonly) NSArray<NSString  *> * allInterfaceNames;
@property (class,nonatomic,strong,readonly) NSArray<Addr_Interface *> * allInterfaces;

@end

/**
 getnameinfo : getaddrinfo的逆操作 Thread safety
 
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
     NI_IDN         查找过程中找到的名称将从IDN格式转换为区域设置编码(如有必要)。仅ASCII名称不受影响,从而使此标志在现有程序和环境中可用。
     NI_IDN_ALLOW_UNASSIGNED     对应IDNA处理过程中的 IDNA_ALLOW_UNASSIGNED
     NI_IDN_USE_STD3_ASCII_RULES 对应IDNA处理过程中的 IDNA_USE_STD3_ASCII_RULES
 @return success: 0  failed: 1-15 (netdb.h)
 */
int getnameinfo(const struct sockaddr * __restrict addr, socklen_t addrlen,
                                 char * __restrict host, socklen_t hostlen,
                                 char * __restrict serv, socklen_t servlen,
                                  int              flags);
FOUNDATION_EXPORT void sockaddr_getInfo(struct sockaddr *sockaddr,char host[NI_MAXHOST],char service[NI_MAXSERV]);
FOUNDATION_EXPORT void sockaddr_desc(struct sockaddr *sockaddr,const char *name);

