//
//  PLMN.h
//  NetWork
//
//  Created by zhouqiang on 02/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 IMSI: International Mobile Subscriber Identity 国际移动用户识别码
 PLMN: Public Land Mobile Network 公共陆地移动网络
 HNI : Home Network Identity PLMN的不同叫法
 MCC : Mobile Country Code  移动国家代码 由国际电联(ITU)统一分配，唯一识别移动用户所属的国家，MCC共3位,中国地区的MCC为460
 MNC : Mobile Network Code  移动网络代码 长度由MCC的值决定,2位(欧洲标准)或3位(北美标准)
 MSIN: Mobile Subscription Identification Number 移动订户识别代码,由运营商自行分配 (9~10位,取决于MNC的长度)
 IMSI = MCC + MNC + MSIN
        ---------
           PLMN
 
 MCC    MNC    运营商
 460    00    中国移动
 460    01    中国联通
 460    02    中国移动
 460    03    中国电信
 460    04    中国卫通
 460    05    中国电信
 460    06    中国联通
 460    07    中国移动
//460    11    中国电信
 460    20    中国铁通
 */
NS_ASSUME_NONNULL_BEGIN
@interface PLMN : NSObject
//
@property (nonatomic, copy, readonly) NSString  *MCC;
//
@property (nonatomic, copy, readonly) NSString  *MNC;
//国家简写(ISO 3166标准)
@property (nonatomic, copy, readonly) NSString  *ISO;
//国家
@property (nonatomic, copy, readonly) NSString  *country;
//国家代码
@property (nullable, nonatomic, copy, readonly) NSString  *countryCode;
//运营商网络名称
@property (nullable, nonatomic, copy, readonly) NSString  *network;
//移动用户识别代码
@property (nullable, nonatomic, copy, readonly) NSString  *MSIN;

- (instancetype)initWithMCC:(NSString *)MCC
                        MNC:(NSString *)MNC
                        ISO:(NSString *)ISO
                    country:(NSString *)country
                countryCode:(nullable NSString *)countryCode
                    network:(nullable NSString *)network
                       MSIN:(nullable NSString *)MSIN;
@end
NS_ASSUME_NONNULL_END
