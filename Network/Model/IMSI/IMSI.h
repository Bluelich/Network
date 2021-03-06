//
//  IMSI.h
//  Network
//
//  Created by zhouqiang on 14/12/2017.
//

#import <Foundation/Foundation.h>

/**
 MSISDN:Mobile Subscriber International ISDN number 移动台国际用户识别码
 
 IMSI: International Mobile Subscriber Identity 国际移动用户识别码
 
 PLMN: Public Land Mobile Network 公共陆地移动网络
 
 HNI : Home Network Identity PLMN的不同叫法
 
 MCC : Mobile Country Code  移动国家代码 由国际电联(ITU)统一分配，唯一识别移动用户所属的国家，MCC共3位,中国地区的MCC为460
 
 MNC : Mobile Network Code  移动网络代码 长度由MCC的值决定,2位(欧洲标准)或3位(北美标准)
 
 MSIN: Mobile Subscription Identification Number 移动订户识别代码,由运营商自行分配 (9~10位,取决于MNC的长度)
 
 IMSI = MCC + MNC + MSIN
 
        ---------
 
          PLMN
 */
NS_ASSUME_NONNULL_BEGIN
@interface IMSI : NSObject
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
//移动用户识别代码(国内的是10位10进制数)
@property (nullable, nonatomic, copy) NSString  *MSIN;

- (instancetype)initWithMCC:(NSString *)MCC
                        MNC:(NSString *)MNC
                        ISO:(NSString *)ISO
                    country:(NSString *)country
                countryCode:(nullable NSString *)countryCode
                    network:(nullable NSString *)network;
@end
NS_ASSUME_NONNULL_END

