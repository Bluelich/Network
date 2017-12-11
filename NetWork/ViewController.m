//
//  ViewController.m
//  NetWork
//
//  Created by zhouqiang on 30/11/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import "ViewController.h"
#import "NetWorkStatusManager.h"
#import <CFNetwork/CFNetwork.h>
#import <CoreFoundation/CoreFoundation.h>
#import <sys/event.h>
#import <dns_sd.h>

@interface ViewController ()<NSNetServiceDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [NetWorkStatusManager shared];
    
    
    kqueue();
    CFNetServiceRef service = CFNetServiceCreate(kCFAllocatorDefault, (__bridge CFStringRef)@"https://www.meishubao.com", kCFStreamNetworkServiceType, (__bridge CFStringRef)@"name", 111);
    CFNetServiceSetClient(service, NULL, NULL);
    CFNetServiceScheduleWithRunLoop(service, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    
    
    NSNetService *service2 = [[NSNetService alloc] initWithDomain:@"local." type:@"_http._tcp." name:@"name"];
    service2.delegate = self;
    DNSServiceRef dns;
    DNSServiceErrorType err = DNSServiceRegister(&dns, 0, 0, NULL, "_ftp._tcp", NULL, NULL, 80, 10, NULL, NULL, NULL);
    DNSServiceSetDispatchQueue(dns, dispatch_get_global_queue(0, 0));
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
