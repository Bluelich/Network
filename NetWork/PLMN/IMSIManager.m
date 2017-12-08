//
//  IMSIManager.m
//  NetWork
//
//  Created by zhouqiang on 02/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import "IMSIManager.h"
#import "IMSIXMLParser.h"
#import "PLMN.h"

static NSString *const IMSI_PLMN_URL = @"http://www.mcc-mnc.com/";
@interface IMSIManager ()

@property (class,nonatomic,strong,readonly) IMSIManager  *shared;
@property (nonatomic,strong) NSArray<PLMN *> *data;
@property (nonatomic,strong) NSString  *filePath;

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
+ (NSArray<PLMN *> *)allPMLNs
{
    return IMSIManager.shared.data;
}
+ (BOOL)update:(NSError **)err
{
    NSData *data = [IMSIManager.shared fetchData:err];
    if (*err != nil) {
        return NO;
    }
    if (!data) {
        return NO;
    }
    [IMSIManager.shared saveData:data error:err];
    return [IMSIManager.shared updateWithData:data error:err];
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        NSData *data = [IMSI_PLMN_URL dataUsingEncoding:NSUTF8StringEncoding];
        NSString *fileName = [data base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
        self.filePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"html"];
        [self loadLocalData];
    }
    return self;
}
- (void)loadLocalData
{
    NSData *data = [NSData dataWithContentsOfFile:self.filePath];
    if (data) {
        [self updateWithData:data error:nil];
    }
}
- (NSData *)fetchData:(NSError **)error
{
    NSError *err = nil;
    NSMutableString *html = [NSString stringWithContentsOfURL:[NSURL URLWithString:IMSI_PLMN_URL] encoding:NSUTF8StringEncoding error:&err].mutableCopy;
    if (err) {
        *error = err;
        return nil;
    }
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:@"<td>*>(?:[^<]*)(?<noamp>(&(?!amp;))+)(?:[^<]*)</td>" options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators error:&err];
    if (err) {
        *error = err;
        return nil;
    }
    NSArray<NSTextCheckingResult *> *result = [regularExpression matchesInString:html options:NSMatchingReportCompletion range:NSMakeRange(0, html.length)];
    [result enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange range = [obj  rangeWithName:@"noamp"];
        NSString *str = [html substringWithRange:range];
        if ([str isEqualToString:@"&"]) {
            [html replaceCharactersInRange:range withString:@"&amp;"];
        }
    }];
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}
- (void)saveData:(NSData *)data error:(NSError **)error
{
    if (!data) {
        return;
    }
    NSFileManager *manager = NSFileManager.defaultManager;
    if ([manager fileExistsAtPath:self.filePath]) {
        [manager removeItemAtPath:self.filePath error:error];
    }
    if ([data writeToFile:self.filePath atomically:YES]) {
        NSLog(@"写入失败");
    }
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
