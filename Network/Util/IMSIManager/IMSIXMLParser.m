//
//  IMSIXMLParser.m
//  Network
//
//  Created by zhouqiang on 14/12/2017.
//

#import "IMSIXMLParser.h"

@interface IMSIXMLParser ()<NSXMLParserDelegate>
{
    BOOL  _element_tr_begin;
    NSMutableArray  *_attr;
    NSMutableArray<NSString *>  *_each;
    NSMutableString  *_element_tr_td_content;
    NSMutableArray<IMSI *> *_results;
}
@property (nonatomic,strong) NSMutableArray<NSDictionary *> *parserResult;

@end

@implementation IMSIXMLParser
- (BOOL)parse
{
    _attr  = [NSMutableArray array];
    _element_tr_begin = NO;
    self.parserResult = [NSMutableArray array];
    self.delegate = self;
    return [super parse];
}
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(nullable NSString *)namespaceURI qualifiedName:(nullable NSString *)qName attributes:(NSDictionary<NSString *, NSString *> *)attributeDict
{
    if ([elementName isEqualToString:@"tr"]) {
        _element_tr_begin = YES;
        _each = [NSMutableArray array];
    }else if ([elementName isEqualToString:@"td"]){
        _element_tr_td_content = [NSMutableString string];
    }
}
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(nullable NSString *)namespaceURI qualifiedName:(nullable NSString *)qName
{
    if ([elementName isEqualToString:@"tr"]) {
        if (_element_tr_begin) {
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            for (int i = 0; i < _attr.count; i++) {
                [dic setObject:_each[i] forKey:_attr[i]];
            }
            [self.parserResult addObject:dic];
            _element_tr_begin = NO;
        }
    }else if ([elementName isEqualToString:@"td"]){
        [_element_tr_td_content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [_each addObject:_element_tr_td_content];
    }
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (!_element_tr_begin) {
        return;
    }
    if ([string hasPrefix:@"\n"]) {
        return;
    }
    if (_attr.count < 6) {
        [_attr addObject:string];
        if (_attr.count == 6) {
            _element_tr_begin = NO;
        }
        return;
    }
    [_element_tr_td_content appendString:string];
}
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    printf("error:%s",parseError.debugDescription.UTF8String);
}
- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    _results = [NSMutableArray array];
    for (NSDictionary *dic in self.parserResult) {
        IMSI *plmn = [[IMSI alloc] initWithMCC:dic[_attr[0]]
                                           MNC:dic[_attr[1]]
                                           ISO:dic[_attr[2]]
                                       country:dic[_attr[3]]
                                   countryCode:dic[_attr[4]]
                                       network:dic[_attr[5]]];
        [_results addObject:plmn];
    }
}
//文档验证错误
- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError
{
    printf("error:%s",validationError.debugDescription.UTF8String);
}
//- (nullable NSData *)parser:(NSXMLParser *)parser resolveExternalEntityName:(NSString *)name systemID:(nullable NSString *)systemID{}//开始处理外部实体
- (void)parserDidStartDocument:(NSXMLParser *)parser{}
- (void)parser:(NSXMLParser *)parser didStartMappingPrefix:(NSString *)prefix toURI:(NSString *)namespaceURI{}
- (void)parser:(NSXMLParser *)parser didEndMappingPrefix:(NSString *)prefix{}
- (void)parser:(NSXMLParser *)parser foundComment:(NSString *)comment{}//处理注释
- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock{}//处理CDATA
- (void)parser:(NSXMLParser *)parser foundElementDeclarationWithName:(NSString *)elementName model:(NSString *)model{}
- (void)parser:(NSXMLParser *)parser foundInternalEntityDeclarationWithName:(NSString *)name value:(nullable NSString *)value{}
- (void)parser:(NSXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString{}//解析遇到空白
- (void)parser:(NSXMLParser *)parser foundProcessingInstructionWithTarget:(NSString *)target data:(nullable NSString *)data{}//解析处理指令
- (void)parser:(NSXMLParser *)parser foundExternalEntityDeclarationWithName:(NSString *)name publicID:(nullable NSString *)publicID systemID:(nullable NSString *)systemID{}
- (void)parser:(NSXMLParser *)parser foundNotationDeclarationWithName:(NSString *)name publicID:(nullable NSString *)publicID systemID:(nullable NSString *)systemID{}
- (void)parser:(NSXMLParser *)parser foundAttributeDeclarationWithName:(NSString *)attributeName forElement:(NSString *)elementName type:(nullable NSString *)type defaultValue:(nullable NSString *)defaultValue{}
- (void)parser:(NSXMLParser *)parser foundUnparsedEntityDeclarationWithName:(NSString *)name publicID:(nullable NSString *)publicID systemID:(nullable NSString *)systemID notationName:(nullable NSString *)notationName{}
@end

