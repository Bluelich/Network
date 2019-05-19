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
#import "Test.h"

@interface HostInfo:NSObject
@property NSString *h_name;    /* official name of host */
@property NSArray<NSString *> *h_aliases;    /* alias list */
@property int    h_addrtype;    /* host address type */
@property int    h_length;    /* length of address */
@property NSArray<NSString *> *h_addr_list;    /* list of addresses from name server */
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
    struct hostent *host = gethostbyname2(hostName.UTF8String, type);
    gethostent();
    HostInfo *obj = [HostInfo new];
    //
    NSMutableArray *h_addr_list = [[NSMutableArray alloc] init];
    
    for (int i = 0; host->h_addr_list[i]; i++) {
        const char *ip = inet_ntop(type, (const void *)(host->h_addr_list[i]), malloc(length), length);
        if (ip) {
            NSString *val = [NSString stringWithUTF8String:ip];
            [h_addr_list addObject:val];
        }
    }
    obj.h_addr_list = h_addr_list;
    //
    NSMutableArray *h_aliases = [[NSMutableArray alloc] init];
    for (int i = 0; host->h_aliases[i]; i++) {
        NSString *val = [NSString stringWithUTF8String:host->h_aliases[i]];
        [h_aliases addObject:val];
    }
    obj.h_aliases = h_aliases;
    //
    obj.h_name = [NSString stringWithUTF8String:host->h_name];
    obj.h_addrtype = host->h_addrtype;
    obj.h_length = host->h_length;
    return obj;
}
@end
void testSocketConnect(){
    HostInfo *info = [HostInfo infoWithHost:@"bluelich.com" type:AF_INET];
    for (NSString *obj in info.h_addr_list) {
        struct sockaddr addr;
        bzero(&addr, sizeof(struct sockaddr));
        addr.sa_len = sizeof(struct sockaddr);
        addr.sa_family = info.h_addrtype;
        switch (info.h_addrtype) {
            case AF_INET:
                (*(struct sockaddr_in *)&addr).sin_port  = htons(80);
                int retVal = inet_pton(info.h_addrtype, obj.UTF8String, &((*(struct sockaddr_in *)&addr).sin_addr));
                assert(retVal == 1);
                break;
            case AF_INET6:
                (*(struct sockaddr_in6 *)&addr).sin6_port = htons(80);
                retVal = inet_pton(info.h_addrtype, obj.UTF8String, &((*(struct sockaddr_in6 *)&addr).sin6_addr));
                assert(retVal == 1);
                break;
            default:
                return;
        }
        struct timeval time;
        gettimeofday(&time, NULL);
        int start = time.tv_usec;
        printf("\ntry connect to %s",obj.UTF8String);
        int sockfd = socket(info.h_addrtype, SOCK_STREAM,0);
        int retval = connect(sockfd, (struct sockaddr *)&addr, addr.sa_len);
        struct timeval time2;
        gettimeofday(&time2, NULL);
        int end = time2.tv_usec;
        printf("\nconnect:%s %s duration:%f",obj.UTF8String,retval != 0 ? "failed" : "success",(end - start)/1000000.f);
        
        const char *msg = "message to send";
        send(sockfd, msg, sizeof(msg), MSG_OOB);//MSG_OOB MSG_DONTROUTE
        struct msghdr msghdr;
        sendmsg(sockfd, &msghdr, MSG_DONTROUTE);
    }
}
int main(int argc, const char * argv[]) {
    [Reachability.shared setNetworkStatusChangedBlock:^(NetworkStatus status) {
        printf("%s\n",NSStringFromNetworkStatus(status).UTF8String);
    }];
//    socket_connect(@"apple.com");
//    printf("\n\nend\n");
//    proxy_test();
    NSLog(@"getIPAddress:\n%@",getIPAddress());
    testSocketConnect();
    printf("\n\nend\n");
    [NSRunLoop.currentRunLoop run];
    return 0;
}
