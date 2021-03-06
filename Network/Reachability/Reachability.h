//
//  Reachability.h
//  Network
//
//  Created by zhouqiang on 14/12/2017.
//

#import <Foundation/Foundation.h>
#import "IMSIManager.h"
#import "WiFi.h"
#import "ReachabilityDefination.h"
#import "Addr_Interface.h"

/*
 重要: 可达性必须使用 DNS 来解析主机名, 然后才能确定该主机的可到达程度, 这可能需要在某些网络连接上花费时间。
 因此, API 将返回 NotReachable, 直到名称解析完成。此延迟可能在某些网络的接口中可见。
 */
@interface Reachability : NSObject

@property (class,nonatomic,strong) NSString *hostName;
@property (class,nonatomic,strong,readonly) Reachability *shared;
@property (nonatomic,assign,readonly) NetworkStatus     status;
@property (nonatomic,strong,readonly) IMSI             *cellularProvider;
@property (nonatomic,strong,readonly) WiFi             *WiFiInfo;
@property (nonatomic,  copy) void(^networkStatusChangedBlock)(NetworkStatus status);

@end
