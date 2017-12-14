//
//  Test.h
//  Network
//
//  Created by zhouqiang on 13/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "Reachability.h"

bool sockaddr_getInfo2(struct sockaddr *sockaddr,char **host,char **service);
void test1(void);
void test2(void);
const char* getIPV6(const char * mHost);
void getIP(void);
void test_other(void);
bool is_space(unsigned int val);

@interface Task : NSObject
- (void)testMultipeerConnectivity;
- (void)testNetService;
@end
