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
#import <MultipeerConnectivity/MultipeerConnectivity.h>

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

