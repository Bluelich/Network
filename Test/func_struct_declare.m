//
//  func_struct_declare.m
//  Network
//
//  Created by zhouqiang on 18/12/2017.
//

#ifndef func_struct_declare_m
#define func_struct_declare_m

#import "Reachability.h"

/*
 随着运营商和企业逐渐部署ipv6 DNS64/NAT64网络之后，设备被分配的地址会变成ipv6的地址，
 而这些网络就是所谓的ipv6-only网络，并且仍然可以通过此网络去获取ipv4地址提供的内容。
 客户端向服务器端请求域名解析，首先通过DNS64 Server查询ipv6的地址，如果查询不到，再向DNS Server查询ipv4地址，
 通过DNS64 Server合成一个ipv6的地址，最终将一个ipv6的地址返回给客户端。
 
 除了解决 ipv4 枯竭问题, ipv6 比 ipv4 更有效率。
 1.避免了网络地址转换 (NAT) 的需要
 2.通过使用简化的报头通过网络提供更快的路由
 3.防止网络碎片
 4.避免为邻居地址解析广播
 */

/*
 通配地址
 ipv4：0.0.0.0
 ipv6：::
 */

struct addrinfo_my_desc {
    /*
     ai_flags:或运算
     AI_PASSIVE,   AI_CANONNAME,   AI_NUMERICHOST,
     AI_ADDRCONFIG,AI_ALL,         AI_NUMERICSERV,
     AI_V4MAPPED,  AI_V4MAPPED_CFG,AI_DEFAULT
     
     AI_PASSIVE:被动的，用于bind，通常用于server socket
     1.返回的socket地址结构用于bind(2)。主机名为null时,socket地址结构的IP为ipv4(INADDR_ANY)或ipv6(IN6ADDR_ANY_INIT)。
     2.未设置AI_PASSIVE时,用于①.面向连接协议:connect(2)②.无连接协议:connect(2),sendto(2),or sendmsg(2)
     3.如果主机名为null指针且未设置AI_PASSIVE,则socket地址结构的IP部分将设置为loopback地址。
     AI_CANONNAME:解析域名,调用getaddrinfo()成功,会返回一个字符串(第一个addrinfo->ai_canonname->hostname>canonical_name)
     AI_NUMERICHOST:地址为数字串,主机名是ipv4或ipv6地址的数字字符串,不要解析名称
     
     
     AI_NUMERICSERV:提供的非空servname字符串应为数字端口字符串。否则,将返回EAI_NONAME错误。防止调用任意name解析服务(例如NIS+)
     AI_ADDRCONFIG:只有在本地系统上配置了ipv4或ipv6地址后,才会返回对应的ipv4地址或ipv6地址.
     AI_ALL:如果设置了AI_V4MAPPED,那么 getaddrinfo()将返回所有匹配的ipv4和 ipv6地址。未设置AI_V4MAPPED会被忽略。
     AI_V4MAPPED:当ai_family=PF_INET6,无对应的ipv6(ai_addrlen=16)地址时候,会返ipv4转换的ipv6地址. ai_family!=PF_INET6会被忽略
     AI_DEFAULT: 等价于(AI_V4MAPPED_CFG | AI_ADDRCONFIG)
     AI_UNUSABLE:当ai_flags为0时的内部默认值.这会影响AI_V4MAPPED_CFG和AI_ADDRCONFIG的隐式设置,导致结果中包含不可用的地址。
     */
    int    ai_flags;            //或运算 AI_PASSIVE,AI_CANONNAME,AI_NUMERICHOST
    int    ai_family;           // PF_xxx 协议族类型.PF_UNSPEC(任意协议族)
    int    ai_socktype;         // SOCK_xxx 套接字类型: SOCK_STREAM、SOCK_DGRAM 或 SOCK_RAW。0:任意套接字类型
    int    ai_protocol;         //传输协议 0(任意传输协议) or IPPROTO_xxx[ipv4,ipv6],IPPROTO_UDP,IPPROTO_TCP
    socklen_t ai_addrlen;       // ai_addr 的 长度
    char    *ai_canonname;      // canonical name for hostname
    struct    sockaddr *ai_addr;// binary address
    struct    addrinfo *ai_next;// next structure in linked list
};
/*
 ipv6 报头
 
 0~31    版本号(6) + Qos(流量等级) + 流标签(标识同一个流里面的报文)
 32~63   载荷长度 +下一报头　＋　跳数限制
 64~191  源地址
 192~320 目标地址
 
 流标签
 RFC2460对ipv6流标签的特征进行了说明：
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
    __uint8_t       sin6_len;     //total size
    sa_family_t     sin6_family;  //AF_INET6
    in_port_t       sin6_port;    //端口号，网络字节序
    __uint32_t      sin6_flowinfo;//流标签
    struct in6_addr sin6_addr;    //ip地址
    __uint32_t      sin6_scope_id;//网口标识(新版本加的)
};

/*
 对ipv6有更好的支持(如 28(sockaddr_in6) > 16(sockaddr_in))
 能提供严格的结构对齐,支持更大的地址结构
 */
struct sockaddr_storage_desc {
    __uint8_t    ss_len;         //address length
    sa_family_t  ss_family;    //family
    char       __ss_pad1[_SS_PAD1SIZE];
    __int64_t  __ss_align;     //force structure storage alignment
    char       __ss_pad2[_SS_PAD2SIZE];//
};


struct sockaddr_storage a;
//http://blog.csdn.net/u013613341/article/details/50762913
/**
  主机名和地址转换
 \details ipv4 only
 \details 主机名->地址
 @param name 主机名
 @return 地址
 */
struct hostent *gethostbyname(const char *name);

/**
 主机地址转换
 \details ipv4 only
 \details 主机名->地址

 @param addr ipv4地址
 @param len socklen_t
 @param type int
 @return 地址
 */
struct hostent *gethostbyaddr(const void *addr, socklen_t len, int type);
//ipv4,ipv6兼容的转换函数

/**
 \details ipv4 and ipv6

 @param name 主机名
 @param af int AF_INET AF_INET6
 @return 地址
 */
struct hostent *gethostbyname2(const char *name, int af);
/**
 用于获取主机主机名和服务对应的 IP地址和端口号的列表.
 比gethostbyname()和getservbyname()有更大的灵活性.
 hostname和servname必须至少有一个不为空。
 
 @param hostname 有效的主机名或数字主机地址字符串,点式的ipv4或ipv6地址
 @param servname 十进制端口或者/etc/services中列出的,包含十进制数的端口号或服务名如（ftp,http,123）
 @param hints    可以为NULL,由调用者填写关于它所想返回的信息类型的线索.
 
 @param res  aa
 @return  aa
 */
int getaddrinfo(const char * __restrict hostname, const char * __restrict servname,
                const struct addrinfo *  __restrict hints,
                struct addrinfo ** __restrict res);

//在bind或者connect之后就可以释放
void freeaddrinfo(struct addrinfo *ai);
/**
 getnameinfo : getaddrinfo的逆操作 Thread safety
 
 @param addr    sockaddr(ipv4 or ipv6)
 @param addrlen size of addr
 @param host    char *
 @param hostlen size of host
 @param serv    char *
 @param servlen size of serv
 @param flags   NI_NAMEREQD    如果hostname无法确定,会返回错误
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


/*
 void bzero(void *dest,size_t nbytes);//初始化
 void bcopy(const void *src,void *dest,size_t nbytes);//把指定长度的字节从src移动到dest处
 int  bcmp(const void *ptr1, const void *ptr2, size_t nbytes);//比较两个字符串，相等返回0，否则为非0
 
 //主机序 -> 网络字节序 (用于发送时)
 uint16_t htons(uint16_t host16bitvalue);
 uint32_t htonl(uint32_t host32bitvalue);
 
 //网络序 -> 主机序 (用于接收时)
 uint16_t ntohs(uint16_t net16bitvalue);
 uint32_t ntohl(uint32_t net32bitvalue);
 */
/**
 ipv4地址转换函数
 \details 点分十进制的ip字符串 -> 网络字节序
 
 @param strptr 点分十进制的ip字符串  e.g. "192.168.1.123"
 @param addrptr 网络字节序
 @return 若strptr有效，则返回１。否则返回０
 */
int inet_aton(const char *strptr, struct in_addr *addrptr);
/**
 ipv4地址转换函数
 \details点分十进制的ip字符串 -> 网络字节序
 \details出错时返回INADDR_NONE 常值（通常是一个32位均为1的值）
 \details这意味着255.255.255.255 地址串不能由该函数处理。
 
 @param strptr 点分十进制的ip字符串
 @return 网络字节序
 */
in_addr_t inet_addr(const char *strptr);
/**
 ipv4地址转换函数2
 \details 网络字节序 -> 点分十进制的ip字符串
 
 @param inaddr 网络字节序
 @return 点分十进制的ip字符串
 */
char *inet_ntoa(struct in_addr inaddr);



//应尽量使用随ipv6出现的`inet_pton`和`inet_ntop`,以保证ipv4与ipv6的兼容性。
/**
 * @brief ip string -> sockaddr
 * @param family      协议族，AF_INET或AF_INET6
 * @param strptr      字符串地址,e.g. "192.168.1.100"
 * @param addrptr     void *, 通过指针返回in_addr或in6_ddr结构体
 * @returns           success:1，invalid arguments:0，error occured:-1.
 */
int inet_pton(int family, const char *strptr, void *addrptr);

/**
 * @brief sockaddr -> ip string
 * @param family   协议族，AF_INET或AF_INET6
 * @param addrptr  const void *, 要转换的in_addr或in6_addr
 * @param strptr   转换后的字符串
 * @param len      strptr的长度,通常为 INET_ADDRSTRLEN(16 bytes) 或 INET6_ADDRSTRLEN(46 bytes)
 * @returns        若分配给strptr的len不足:errno->ENOSPC。成功则返回指向结构的指针，出错则为NULL。
 */
const char* inet_ntop(int family, const void *addrptr, char *strptr, socklen_t len);



#pragma mark - Socket
/**
 create a socket

 @param domain 协议域，AF_INET
 @param type Socket 类型，  SOCK_STREAM(TCP)/SOCK_DGRAM(UDP，报文)
 @param protocol IPPROTO_TCP，协议，如果输入0，可以根据第二个参数，自动选择协议
 @return 如果 > 0 就表示成功
 */
int socket(int domain, int type, int protocol);


/**
 connect

 @param socket 客户端socket
 @param address 指向数据结构sockaddr的指针，其中包括目的端口和IP地址,服务器的"结构体"地址
 @param address_len 结构体数据长度
 @return 0:成功  其他:错误代号
 */
int connect(int socket, const struct sockaddr *address, socklen_t address_len);
int connectx(int socket, const sa_endpoints_t *endpoints, sae_associd_t associd,unsigned int flags,
             const struct iovec *iov, unsigned int iovcnt, size_t *len, sae_connid_t *connid);
int disconnectx(int socket, sae_associd_t associd, sae_connid_t connid);

//仅方便记忆
//http://www.360doc.com/content/16/1104/16/496343_603923523.shtml
typedef NS_ENUM(NSUInteger, _socket_flag) {
    _socket_flag_MSG_DONTROUTE  = MSG_DONTROUTE,//send可用 bypass routing, use direct interface
//    _socket_flag_MSG_DONWAIT   = MSG_DONWAIT,//send与recv都可用
    _socket_flag_MSG_PEEK       = MSG_PEEK,//recv可用
    _socket_flag_MSG_WAITALL    = MSG_WAITALL,//recv可用 wait for full request or error
    _socket_flag_MSG_OOB        = MSG_OOB,//send可用  process out-of-band data
    _socket_flag_MSG_EOR        = MSG_EOR,//send与recv都可用 data completes record
    _socket_flag_MSG_TRUNC      = MSG_TRUNC, //data discarded before delivery
    _socket_flag_MSG_CTRUNC     = MSG_CTRUNC,//control data lost before delivery
#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)
    _socket_flag_MSG_DONTWAIT   = MSG_DONTWAIT,//this message should be nonblocking */
    _socket_flag_MSG_EOF        = MSG_EOF,// data completes connection */
    #ifdef __APPLE__
        #ifdef __APPLE_API_OBSOLETE
    _socket_flag_MSG_WAITSTREAM = MSG_WAITSTREAM,// wait up to full request.. may return partial */
        #endif
    _socket_flag_MSG_FLUSH      = MSG_FLUSH ,//Start of 'hold' seq; dump so_temp */
    _socket_flag_MSG_HOLD       = MSG_HOLD,//Hold frag in so_temp */
    _socket_flag_MSG_SEND       = MSG_SEND,//Send the packet in so_temp */
    _socket_flag_MSG_HAVEMORE   = MSG_HAVEMORE,//Data ready to be read */
    _socket_flag_MSG_RCVMORE    = MSG_RCVMORE,//Data remains in current pkt */
    #endif
    _socket_flag_MSG_NEEDSA     = MSG_NEEDSA,//Fail receive if socket address cannot be allocated */
#endif
};

/**
 send data

 @param socket 客户端socket
 @param buffer 发送内容地址
 @param length 发送内容长度
 @param flags 发送方式标志，一般为0 _socket_flag
 @return 如果成功，则返回发送的字节数，失败则返回 -1
 */
ssize_t send(int socket, const void *buffer, size_t length, int flags);
ssize_t sendmsg(int socket, const struct msghdr *message, int flags);
ssize_t sendto(int socket, const void *buffer, size_t length, int flags,
               const struct sockaddr *dest_addr, socklen_t dest_len);


struct cmsghdr_desc  {
    socklen_t cmsg_len ;// 包含该头部的数据长度
    int  cmsg_level;    // 具体的协议标识
    int  cmsg_type;     //协议中的类型
} ;
struct msghdr_desc {
    void         *msg_name;      //消息的协议地址\
                                 //协议地址和套接口信息，在非连接的UDP中，发送者要指定对方地址端口，接受方用于的到数据来源
                                 //如果不需要的话可以设置为NULL（在TCP或者连接的UDP中，一般设置为NULL）
    socklen_t     msg_namelen;   //地址的长度
    struct iovec *msg_iov;       //多io缓冲区的地址
    int           msg_iovlen;    //缓冲区的个数
    void         *msg_control;   //辅助数据的地址,结构见cmsghdr_desc
    socklen_t     msg_controllen;//辅助数据的长度
    int           msg_flags;     //接收消息的标识
};
/**
 receive data
 
 @param socket 创建的socket
 @param buffer 接收内容的地址
 @param length 接收内容的长度
 @param flags 接收数据的标记 0，就是阻塞式，一直等待服务器的数据
 @return 如果成功，则接收到的数据长度，失败则返回 -1
 */
ssize_t recv(int socket, void *buffer, size_t length, int flags);
ssize_t recvfrom(int socket, void *restrict buffer, size_t length, int flags,
         struct sockaddr *restrict address, socklen_t *restrict address_len);
ssize_t recvmsg(int socket, struct msghdr *message, int flags);

/**
 close socket

 @param sockfd 创建的socket
 @return 无错误,返回0,否则返回...
 */
int close(int sockfd);

/**
 选择性关闭
 
 @param sockfd 创建的socket
 @param how SHUT_RD  : shut down the reading side
            SHUT_WR  : shut down the writing side
            SHUT_RDWR: shut down both sides,same to close(int)
 @return a
 */
int shutdown(int sockfd, int how);
/**
 other
 */
int  sockatmark(int s);
int  listen(int socket, int backlog);
void pfctlinput(int cmd, struct sockaddr *sa);
int  socketpair(int domain, int type, int protocol, int socket_vector[2]);
int  sendfile(int fd, int s, off_t offset, off_t *len, struct sf_hdtr *hdtr, int flags);
int  accept(int sockfd, struct sockaddr * __restrict addr, socklen_t * __restrict addrlen);
int  getpeername(int socket, struct sockaddr *restrict address, socklen_t *restrict address_len);
int  getsockname(int socket, struct sockaddr *restrict address, socklen_t *restrict address_len);
int  setsockopt(int socket, int level, int option_name, const void *option_value, socklen_t option_len);
int  getsockopt(int socket, int level, int option_name, void *restrict option_value, socklen_t *restrict option_len);
int  bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);

void test(){
    
}
#endif /* func_struct_declare_m */
