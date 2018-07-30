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

int main(int argc, const char * argv[]) {
    [Reachability.shared setNetworkStatusChangedBlock:^(NetworkStatus status) {
        printf("%s\n",NSStringFromNetworkStatus(status).UTF8String);
    }];
//    socket_connect(@"apple.com");
//    printf("\n\nend\n");
//    proxy_test();
    NSLog(@"getIPAddress:\n%@",getIPAddress());
    [NSRunLoop.currentRunLoop run];
    return 0;
}
