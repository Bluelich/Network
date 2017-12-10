//
//  IMSIManager.m
//  NetWork
//
//  Created by zhouqiang on 02/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import "IMSIManager.h"
#import "IMSIXMLParser.h"

static NSString * const kIMSI_PLMN_RESOURCE_URL = @"http://www.mcc-mnc.com/";
@interface IMSIManager ()
@property (class,nonatomic,strong,readonly) IMSIManager  *shared;
@property (nonatomic,strong) NSArray<PLMN *> *data;
@property (nonatomic,strong) NSString  *filePath;
@end

@implementation IMSIManager
+ (void)load
{
    if (IMSIManager.allPMLNs.count == 0) {
        NSError *error = nil;
        [IMSIManager update:&error];
    }
}
+ (instancetype)shared
{
    static IMSIManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = IMSIManager.new;
        NSData *data = [kIMSI_PLMN_RESOURCE_URL dataUsingEncoding:NSUTF8StringEncoding];
        NSString *fileName = [data base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
        manager.filePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"html"];
        [manager loadLocalData:nil];
    });
    return manager;
}
+ (NSArray<PLMN *> *)allPMLNs
{
    return IMSIManager.shared.data;
}
+ (BOOL)update:(NSError **)err
{
    NSData *data = [IMSIManager.shared fetchData:err];
    if (*err != nil || !data) {
        return NO;
    }
    /*
     NSDataWritingAtomic//等同于atomically == YES
     NSDataWritingWithoutOverwriting//禁止文件覆盖
     NSDataWritingFileProtectionNone//任意读写
     NSDataWritingFileProtectionComplete//仅在设备解锁时可读写
     NSDataWritingFileProtectionCompleteUnlessOpen//设备锁定时未打开的文件,不可读写,但可创建文件
     NSDataWritingFileProtectionCompleteUntilFirstUserAuthentication//首次用户授权前需解锁后可读写,其余不受限制
     NSDataWritingFileProtectionMask//在确定分配给数据的文件保护选项时要使用的掩码
     */
    [data writeToFile:IMSIManager.shared.filePath options:NSDataWritingAtomic | NSDataWritingFileProtectionNone error:err];
    [data writeToFile:IMSIManager.shared.filePath atomically:YES];
    return [IMSIManager.shared updateWithData:data error:err];
}
+ (PLMN *)infoForMCC:(NSString *)MCC MNC:(NSString *)MNC
{
    return [self.shared infoForMCC:MCC MNC:MNC];
}
#pragma mark -
- (PLMN *)infoForMCC:(NSString *)MCC MNC:(NSString *)MNC
{
    if (self.data.count == 0) {
        return nil;
    }
    __block PLMN *res = nil;
    [self.data enumerateObjectsUsingBlock:^(PLMN * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.MCC isEqualToString:MCC] && [obj.MNC isEqualToString:MNC]) {
            res = obj;
            *stop = YES;
        }
    }];
    return res;
}
- (void)loadLocalData:(NSError **)error
{
    /*
     NSDataReadingMappedIfSafe//尽可能安全地对文件进行内存映射
     NSDataReadingUncached//不允许文件系统缓存该文件
     NSDataReadingMappedAlways//尽可能对文件进行内存映射.优先级高于NSDataReadingMappedIfSafe
     */
    NSData *data = [NSData dataWithContentsOfFile:self.filePath options:NSDataReadingMappedIfSafe error:error];
    if (data) {
        [self updateWithData:data error:nil];
    }
}
- (NSData *)fetchData:(NSError **)error
{
    NSError *err = nil;
    NSMutableString *html = [NSString stringWithContentsOfURL:[NSURL URLWithString:kIMSI_PLMN_RESOURCE_URL] encoding:NSUTF8StringEncoding error:&err].mutableCopy;
    if (err) {
        if (error) {
            *error = err;
        }
        return nil;
    }
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:@"<td>*>(?:[^<]*)(?<noamp>(&(?!amp;))+)(?:[^<]*)</td>" options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators error:&err];
    if (err) {
        if (error) {
            *error = err;
        }
        return nil;
    }
    NSArray<NSTextCheckingResult *> *result = [regularExpression matchesInString:html options:NSMatchingReportCompletion range:NSMakeRange(0, html.length)];
    [result enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange range = NSMakeRange(0, 0);
        if (@available(iOS 11.0, *)) {
            range = [obj  rangeWithName:@"noamp"];
        } else {
            range = [obj rangeAtIndex:1];
        }
        NSString *str = [html substringWithRange:range];
        if ([str isEqualToString:@"&"]) {
            [html replaceCharactersInRange:range withString:@"&amp;"];
        }
    }];
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}
- (BOOL)updateWithData:(NSData *)data error:(NSError **)error
{
    IMSIXMLParser *parser = [[IMSIXMLParser alloc] initWithData:data];
    [parser parse];
    if (parser.parserError) {
        *error = parser.parserError;
        return NO;
    }
    self.data = parser.results;
    return YES;
}
@end
