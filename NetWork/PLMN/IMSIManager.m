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

static NSString * const kIMSI_PLMN_RESOURCE_URL = @"http://www.mcc-mnc.com/";
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
    if (*err != nil || !data) {
        return NO;
    }
    [data writeToFile:IMSIManager.shared.filePath options:NSDataWritingAtomic error:err];
    return [IMSIManager.shared updateWithData:data error:err];
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        NSData *data = [kIMSI_PLMN_RESOURCE_URL dataUsingEncoding:NSUTF8StringEncoding];
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
    NSMutableString *html = [NSString stringWithContentsOfURL:[NSURL URLWithString:kIMSI_PLMN_RESOURCE_URL] encoding:NSUTF8StringEncoding error:&err].mutableCopy;
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
