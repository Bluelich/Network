//
//  IMSIManager.m
//  NetWork
//
//  Created by zhouqiang on 02/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import "IMSIManager.h"
#import "IMSIXMLParser.h"

@interface IMSIManager ()
@property (class,nonatomic,strong,readonly) IMSIManager  *shared;
@end
@implementation IMSIManager
+ (instancetype)shared
{
    static IMSIManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = IMSIManager.new;
    });
    return manager;
}
+ (void)update
{
    [IMSIManager.shared update];
}
- (NSArray<NSDictionary *> *)update
{
    static NSString *const url = @"http://www.mcc-mnc.com/";
    IMSIXMLParser *parser = [[IMSIXMLParser alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
    [parser parse];
    return parser.results;
}
@end
