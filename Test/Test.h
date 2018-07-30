//
//  Test.h
//  Network
//
//  Created by zhouqiang on 13/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "Reachability.h"
#import <YYModel.h>

bool sockaddr_getInfo2(struct sockaddr *sockaddr,char **host,char **service);
void test1(void);
void test2(void);
const char* getIPV6(const char * mHost);
void getIP(void);
void test_other(void);
bool is_space(unsigned int val);
long long doTask(void (^block)(void));

NSDictionary *getIPAddress(void);

void CFSocketTest(void);

void socket_connect(NSString *host);
NSString *proxy_test(void);

@interface h_addr_list_obj : NSObject
@property const void *addr;
@property const char *host;
@end

@interface HostInfo:NSObject
@property NSString *hostName;
@property NSString *h_name;    /* official name of host */
@property NSArray<NSString *> *h_aliases;    /* alias list */
@property int    h_addrtype;    /* host address type */
@property int    h_length;    /* length of address */
@property NSArray<h_addr_list_obj *> *h_addr_list; /* list of addresses from name server */
@property int    sockaddr_length;
+ (instancetype)infoWithHost:(NSString *)hostName type:(int)type;
@end

@interface Task : NSObject
- (void)testMultipeerConnectivity;
- (void)testNetService;
@end
