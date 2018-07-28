//
//  main.m
//  Network_Mac
//
//  Created by zhouqiang on 14/12/2017.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
#import <sys/time.h>
#import "Addr_Interface.h"
#import <YYModel.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface h_addr_list_obj : NSObject
@property const void *addr;
@property const char *host;
@end
@implementation h_addr_list_obj
- (NSString *)description
{
    if (!self.host) {
        return nil;
    }
    return [NSString stringWithUTF8String:self.host];
}
@end

@interface HostInfo:NSObject
@property NSString *hostName;
@property NSString *h_name;    /* official name of host */
@property NSArray<NSString *> *h_aliases;    /* alias list */
@property int    h_addrtype;    /* host address type */
@property int    h_length;    /* length of address */
@property NSArray<h_addr_list_obj *> *h_addr_list; /* list of addresses from name server */
@property int    sockaddr_length;
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

void proxy_test(NSString *host){
    printf("%s:%s\n\n",host.UTF8String,NetworkHasAgentProxy(host) ? "YES" : "NO");
}

int main(int argc, const char * argv[]) {
    socket_connect(@"apple.com");
    printf("\n\nend\n");
    [Reachability.shared setNetworkStatusChangedBlock:^(NetworkStatus status) {
        printf("%s\n",NSStringFromNetworkStatus(status).UTF8String);
    }];
    proxy_test(@"apple.com");
    proxy_test(@"www.apple.com");
    proxy_test(@"http://www.apple.com");
    proxy_test(@"https://www.apple.com");
    proxy_test(@"google.com");
    proxy_test(@"www.google.com");
    proxy_test(@"http://www.google.com");
    proxy_test(@"https://www.google.com");
    [NSRunLoop.currentRunLoop run];
    return 0;
}
