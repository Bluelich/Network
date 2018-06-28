//
//  main.m
//  Network_Mac
//
//  Created by zhouqiang on 14/12/2017.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
#import <sys/time.h>

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
    HostInfo *obj = [HostInfo new];
    NSMutableArray *h_addr_list = [[NSMutableArray alloc] init];
    int h_addr_list_count = 0;
    while (host->h_addr_list[h_addr_list_count]) {
        struct sockaddr sockaddrs = ((struct sockaddr *)host->h_addr_list)[h_addr_list_count];
        const char *ip = inet_ntop(type, &sockaddrs, malloc(length), length);
        if (ip) {
            NSString *val = [NSString stringWithUTF8String:ip];
            [h_addr_list addObject:val];
        }
        h_addr_list_count++;
    }
    obj.h_addr_list = h_addr_list;
    obj.h_name = [NSString stringWithUTF8String:host->h_name];
    obj.h_addrtype = host->h_addrtype;
    obj.h_length = host->h_length;
    NSMutableArray *h_aliases = [[NSMutableArray alloc] init];
    int h_aliases_count = 0;
    while (host->h_aliases[h_aliases_count]) {
        NSString *val = [NSString stringWithUTF8String:host->h_aliases[h_aliases_count]];
        [h_aliases addObject:val];
    }
    obj.h_aliases = h_aliases;
    return obj;
}
@end
int main(int argc, const char * argv[]) {
    [Reachability.shared setNetworkStatusChangedBlock:^(NetworkStatus status) {
        printf("%s\n",NSStringFromNetworkStatus(status).UTF8String);
    }];
    int sockfd = socket(AF_INET, SOCK_STREAM,0);
    if (sockfd == -1) {
        printf("socket error\n");
        exit(0);
    }
    HostInfo *info = [HostInfo infoWithHost:@"example.com" type:AF_INET];
    for (NSString *obj in info.h_addr_list) {
        struct sockaddr_in serv_addr;
        struct in_addr sin_addr;
        int retval = inet_pton(info.h_addrtype, obj.UTF8String, &sin_addr);
        if (retval != 1) {
            continue;
        }
        // 先清零，然后用struct sockaddr_in来填值
        bzero(&serv_addr, sizeof(serv_addr));
        serv_addr.sin_family = info.h_addrtype;
#define SERVPORT 80
        serv_addr.sin_port = htons(SERVPORT);
        serv_addr.sin_addr = sin_addr;
        struct timeval time;
        gettimeofday(&time, NULL);
        int start = time.tv_usec;
        retval =  connect(sockfd, (struct sockaddr *)&serv_addr, sizeof(struct sockaddr_in));
        struct timeval time2;
        gettimeofday(&time2, NULL);
        int end = time2.tv_usec;
        int duration = end - start;
        if (end < start) {
            duration = 1000000 - start + end;
        }
        if (retval != 0) {
            printf("\nconnect:%s failed duration:%d",obj.UTF8String,duration);
            continue;
        }
        printf("\nconnect:%s success duration:%d",obj.UTF8String,duration);
    }
    printf("\nend");
    [NSRunLoop.currentRunLoop run];
    return 0;
}
