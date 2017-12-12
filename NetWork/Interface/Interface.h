//
//  Interface.h
//  NetWork
//
//  Created by zhouqiang on 12/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <net/if.h>


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
//sin_family
typedef NS_ENUM(NSUInteger, addr_sin_family) {
    addr_sin_family_AF_UNSPEC           = AF_UNSPEC,         /* unspecified */
    addr_sin_family_AF_UNIX             = AF_UNIX,         /* local to host (pipes) */
#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)
    addr_sin_family_AF_LOCAL            = AF_LOCAL,        /* backward compatibility */
#endif
    addr_sin_family_AF_INET             = AF_INET,         /* internetwork: UDP, TCP, etc. */
#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)
    addr_sin_family_AF_IMPLINK          = AF_IMPLINK,         /* arpanet imp addresses */
    addr_sin_family_AF_PUP              = AF_PUP,         /* pup protocols: e.g. BSP */
    addr_sin_family_AF_CHAOS            = AF_CHAOS,         /* mit CHAOS protocols */
    addr_sin_family_AF_NS               = AF_NS,        /* XEROX NS protocols */
    addr_sin_family_AF_ISO              = AF_ISO,        /* ISO protocols */
    addr_sin_family_AF_OSI              = AF_OSI,
    addr_sin_family_AF_ECMA             = AF_ECMA,        /* European computer manufacturers */
    addr_sin_family_AF_DATAKIT          = AF_DATAKIT,         /* datakit protocols */
    addr_sin_family_AF_CCITT            = AF_CCITT,        /* CCITT protocols, X.25 etc */
    addr_sin_family_AF_SNA              = AF_SNA,        /* IBM SNA */
    addr_sin_family_AF_DECnet           = AF_DECnet,       /* DECnet */
    addr_sin_family_AF_DLI              = AF_DLI,       /* DEC Direct data link interface */
    addr_sin_family_AF_LAT              = AF_LAT,        /* LAT */
    addr_sin_family_AF_HYLINK           = AF_HYLINK,        /* NSC Hyperchannel */
    addr_sin_family_AF_APPLETALK        = AF_APPLETALK,        /* Apple Talk */
    addr_sin_family_AF_ROUTE            = AF_ROUTE,      /* Internal Routing Protocol */
    addr_sin_family_AF_LINK             = AF_LINK ,       /* Link layer interface */
    addr_sin_family_pseudo_AF_XTP       = pseudo_AF_XTP,       /* eXpress Transfer Protocol (no AF) */
    addr_sin_family_AF_COIP             = AF_COIP,       /* connection-oriented IP, aka ST II */
    addr_sin_family_AF_CNT              = AF_CNT,       /* Computer Network Technology */
    addr_sin_family_pseudo_AF_RTIP      = pseudo_AF_RTIP,      /* Help Identify RTIP packets */
    addr_sin_family_AF_IPX              = AF_IPX,      /* Novell Internet Protocol */
    addr_sin_family_AF_SIP              = AF_SIP,      /* Simple Internet Protocol */
    addr_sin_family_pseudo_AF_PIP       = pseudo_AF_PIP,       /* Help Identify PIP packets */
    addr_sin_family_AF_NDRV             = AF_NDRV,       /* Network Driver 'raw' access */
    addr_sin_family_AF_ISDN             = AF_ISDN ,       /* Integrated Services Digital Network */
    addr_sin_family_AF_E164             = AF_E164,        /* CCITT E.164 recommendation */
    addr_sin_family_pseudo_AF_KEY       = pseudo_AF_KEY,        /* Internal key-management function */
#endif
    addr_sin_family_AF_INET6            = AF_INET6,        /* IPv6 */
#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)
    addr_sin_family_AF_NATM             = AF_NATM,        /* native ATM access */
    addr_sin_family_AF_SYSTEM           = AF_SYSTEM,        /* Kernel event messages */
    addr_sin_family_AF_NETBIOS          = AF_NETBIOS,       /* NetBIOS */
    addr_sin_family_AF_PPP              = AF_PPP,        /* PPP communication protocol */
    addr_sin_family_pseudo_AF_HDRCMPLT  = pseudo_AF_HDRCMPLT,        /* Used by BPF to not rewrite headers in interface output routine */
    addr_sin_family_AF_RESERVED_36      = AF_RESERVED_36,       /* Reserved for internal usage */
    addr_sin_family_AF_IEEE80211        = AF_IEEE80211,       /* IEEE 802.11 protocol */
    addr_sin_family_AF_UTUN             = AF_UTUN,
    addr_sin_family_AF_MAX              = AF_MAX,
#endif
};
typedef NS_ENUM(NSUInteger, Address_format) {
    Address_format_other  = 0,
    Address_format_ipv4   = AF_INET,
    Address_format_ipv6   = AF_INET6,
};

@interface Interface : NSObject

+ (NSArray<Interface *> *)allInterfaces;
+ (NSArray<NSString  *> *)allInterfaceNames;
@end
FOUNDATION_EXPORT NSString *NSStringFrom_if_flags(if_flags flags);
FOUNDATION_EXPORT NSString *NSStringFrom_addr_sin_family(addr_sin_family family);

