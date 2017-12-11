//
//  libxmlParser.m
//  NetWork
//
//  Created by zhouqiang on 02/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import "libxmlParser.h"
#import <libxml2/libxml/parser.h>
#import <libxml2/libxml/tree.h>
#import <libxml2/libxml/xpath.h>
#import <iconv.h>


/*
 http://blog.csdn.net/pbymw8iwm/article/details/7899156
 http://blog.csdn.net/shanzhizi/article/details/7726679
 https://www.cnblogs.com/Anker/p/3542058.html
 http://www.blogjava.net/wxb_nudt/archive/2007/11/18/161340.html
 http://blog.csdn.net/veryhehe2011/article/details/23272927
 http://www.gnu.org/savannah-checkouts/gnu/libiconv/documentation/libiconv-1.15/iconvctl.3.html
 */

/*
 1.内部字符类型xmlChar
 xmlChar是Libxml2中的字符类型，库中所有字符、字符串都是基于这个数据类型。事实上他的定义是 : typedef unsigned char xmlChar;
 使用unsigned char作为内部字符格式是考虑到他能非常好适应UTF-8编码，而UTF-8编码正是libxml2的内部编码，其他格式的编码要转换为这个编码才能在libxml2中使用。
 还经常能看到使用xmlChar*作为字符串类型，非常多函数会返回一个动态分配内存的xmlChar*变量，使用这样的函数时记得要手动删除内存。
 2.xmlChar相关函数
 如同标准c中的char类型相同，xmlChar也有动态内存分配、字符串操作等相关函数。
 例如xmlMalloc是动态分配内存的函数；xmlFree是配套的释放内存函数；xmlStrcmp是字符串比较函数等等。
 基本上xmlChar字符串相关函数都在xmlstring.h中定义；而动态内存分配函数在xmlmemory.h中定义。
 3.xmlChar*和其他类型之间的转换
 另外要注意，因为总是要在xmlChar*和char*之间进行类型转换，所以定义了一个宏BAD_CAST，其定义如下：xmlstring.h
 #define BAD_CAST (xmlChar *) 原则上来说，unsigned char和char之间进行强制类型转换是没有问题的。
 4.文件类型xmlDoc、指针xmlDocPtr
 xmlDoc是个struct，保存了一个xml的相关信息，例如文件名、文件类型、子节点等等；xmlDocPtr等于xmlDoc*，他搞成这个样子总让人以为是智能指针，其实不是，要手动删除的。
 xmlNewDoc函数创建一个新的文件指针。
 xmlParseFile函数以默认方式读入一个UTF-8格式的文件，并返回文件指针。
 xmlReadFile函数读入一个带有某种编码的xml文件，并返回文件指针；细节见libxml2参考手册。
 xmlFreeDoc释放文件指针。特别注意，当你调用xmlFreeDoc时，该文件所有包含的节点内存都被释放，所以一般来说不必手动调用xmlFreeNode或xmlFreeNodeList来释放动态分配的节点内存，除非你把该节点从文件中移除了。一般来说，一个文件中所有节点都应该动态分配，然后加入文件，最后调用xmlFreeDoc一次释放所有节点申请的动态内存，这也是为什么我们非常少看见xmlNodeFree的原因。
 xmlSaveFile将文件以默认方式存入一个文件。
 xmlSaveFormatFileEnc可将文件以某种编码/格式存入一个文件中。
 5.节点类型xmlNode、指针xmlNodePtr
 节点应该是xml中最重要的元素了，xmlNode代表了xml文件中的一个节点，实现为一个struct，内容非常丰富：tree.h
 节点之间是以链表和树两种方式同时组织起来的，next和prev指针能组成链表，而parent和children能组织为树。同时更有以下重要元素：
 节点中的文字内容：content；
 节点所属文件：doc；
 节点名字：name；
 节点的namespace：ns；
 节点属性列表：properties；
 Xml文件的操作其根本原理就是在节点之间移动、查询节点的各项信息，并进行增加、删除、修改的操作。
 xmlDocSetRootElement函数能将一个节点设置为某个文件的根节点，这是将文件和节点连接起来的重要手段，
 当有了根结点以后，所有子节点就能依次连接上根节点，从而组织成为一个xml树
 6.节点集合类型xmlNodeSet、指针xmlNodeSetPtr
 节点集合代表一个由节点组成的变量，节点集合只作为Xpath的查询结果而出现 xpath.h
 节点集合有三个成员，分别是节点集合的节点数、最大可容纳的节点数，及节点数组头指针。对节点集合中各个节点的访问方式非常简单
 */
/*
void CBLibXMLUtility::saveWithLibXML(map<string,string>& data,const string& fileName)
{
    // create xml document
    xmlDocPtr doc = xmlNewDoc(BAD_CAST"1.0");
    xmlNodePtr root = xmlNewNode(NULL,BAD_CAST"CloudBoxRoot");
    
    //set root
    xmlDocSetRootElement(doc,root);
    
    for(map<string,string>::iterator iter = data.begin(); iter != data.end(); iter++)
    {
        cout<<"key:"<<iter->first<<"   value:"<<iter->second<<endl;
        xmlNewTextChild(root, NULL, BAD_CAST (*iter).first.c_str(), BAD_CAST (*iter).second.c_str());
    }
    
    //save xml
    
    int nRel = xmlSaveFile(fileName.c_str(),doc);
    
    if (nRel != -1)
    {
        cout<<"create a xml:"<<nRel<<"bytes"<<endl;
        //DebugLog("Create a xml %d bytes\n",nRel);
    }
    
    //release
    
    xmlFreeDoc(doc);
}
*/
//http://xmlsoft.org/html/libxml-parser.html
/*
 xmlParseFile: 以默认方式读入一个UTF-8格式的文档，并返回文档指针。
 xmlReadFile : 读入一个带有某种编码的xml文档，并返回文档指针
 xmlFreeDoc  : 释放文档指针
 xmlDocGetRootElement : 函数得到根节点curNode
 */
@implementation libxmlParser
- (void)parser:(NSData *)data
{
    /*
     用xmlReadFile函数读出一个文件指针doc；
     用xmlDocGetRootElement函数得到根节点curNode；
     curNode->xmlChildrenNode就是根节点的子节点集合；
     轮询子节点集合，找到所需的节点，用xmlNodeGetContent取出其内容；
     用xmlHasProp查找含有某个属性的节点；
     取出该节点的属性集合，用xmlGetProp取出其属性值；
     用xmlFreeDoc函数关闭文件指针，并清除本文件中所有节点动态申请的内存。
     
     注意：节点列表的指针依然是xmlNodePtr，属性列表的指针也是xmlAttrPtr，并没有xmlNodeList或xmlAttrList这样的类型。
     看作列表的时候使用他们的next和prev链表指针来进行轮询。只有在Xpath中有xmlNodeSet这种类型
     */
    const char *buffer = data.bytes;
    int length = (int)[data length];
    xmlDoc *doc = xmlParseMemory(buffer, length);//xmlParseFile("test.xml");
    if (doc == NULL) {
        fprintf(stderr, "Document not parsed successfully. \n");
        return;
    }
    xmlNode *root = xmlDocGetRootElement(doc);
    if (root == NULL) {
        fprintf(stderr, "empty document\n");
        xmlFreeDoc(doc);
        return;
    }
    xmlNodePtr curNode = root->xmlChildrenNode;
    xmlNodePtr propNodePtr = curNode;
    while(curNode != NULL){
        /*
        if ((!xmlStrcmp(curNode->name, (const xmlChar *)"newNode1")))
        {
            szKey = xmlNodeGetContent(curNode);
            printf("newNode1: %s"n", szKey);
                   xmlFree(szKey);
        }
         */
        //取出节点中的内容
        int res = xmlStrcmp(curNode->name, (const xmlChar *)"newNode1");
        if (!res) {
            xmlNodeGetContent(curNode);
        }
        //查找带有属性attribute的节点
        xmlAttr *attr = xmlHasProp(curNode,BAD_CAST "attribute");
        if (attr){
            propNodePtr = curNode;
        }
        curNode = curNode->next;
    }
    //查找属性
    xmlAttrPtr attrPtr = propNodePtr->properties;
    while (attrPtr != NULL){
        int res = xmlStrcmp(curNode->name, (const xmlChar *)"attribute");
        if (!res){
            xmlChar *szAttr = xmlGetProp(propNodePtr,BAD_CAST "attribute");
            xmlFree(szAttr);
        }
        attrPtr = attrPtr->next;
    }
    xmlFreeDoc(doc);
}
- (void)createXML
{
    /*
     用xmlNewDoc函数创建一个文件指针doc；
     用xmlNewNode函数创建一个节点指针root_node；
     用xmlDocSetRootElement将root_node设置为doc的根结点；
     给root_node添加一系列的子节点，并设置子节点的内容和属性；
     用xmlSaveFile将xml文件存入文件；
     用xmlFreeDoc函数关闭文件指针，并清除本文件中所有节点动态申请的内存。
     
     添加子节点的方式
     1.xmlNewTextChild直接添加一个文本子节点；
     2.先创建新节点，然后用xmlAddChild将新节点加入上层节点
     
     */
    
    xmlMemMalloc(100);
    xmlDoc  *doc  = xmlNewDoc(BAD_CAST("1.0"));
    xmlNode *root = xmlNewNode(NULL, BAD_CAST"root");
    xmlDocSetRootElement(doc, root);
    for (int i = 0; i < 10; i++) {
        char *nodeName = nil;
        snprintf(nodeName, 1, "newNode %d",i);
        char *nodeContent = nil;
        snprintf(nodeContent, 1, "newNode content %d",i);
        //xmlNode *node =
        xmlNewTextChild(root, NULL, BAD_CAST nodeName, BAD_CAST nodeContent);
    }
    xmlNode *node = xmlNewChild(root, NULL, BAD_CAST "node1",BAD_CAST "content of node1");
//    xmlAttr *attr =
    xmlNewProp(node, BAD_CAST "attribute", BAD_CAST "yes");
    xmlNode *sub_node = xmlNewText(BAD_CAST"other way to create content");
    xmlAddChild(node, sub_node);
    xmlSaveFileEnc("filename", doc, "UTF-8");
    xmlFreeDoc(doc);
    xmlCleanupParser();
    xmlMemoryDump();
    xmlCleanupMemory();
    xmlCleanupGlobals();
    xmlCleanupThreads();
    xmlDictCleanup();
    xmlCleanupEncodingAliases();
    xmlCleanupPredefinedEntities();
    xmlCleanupCharEncodingHandlers();
    xmlCleanupInputCallbacks();
    xmlCleanupOutputCallbacks();
}
#pragma makr - 修改
- (void)query:(xmlDoc *)doc
{
    /*
     使用XPATH查找xml文件
     XPATH之于xml，好比SQL之于关系数据库。
     要在一个复杂的xml文件中查找所需的信息，需要用XPATH(语法)
     http://www.zvon.org/xxl/XPathTutorial/General_chi/examples.html
     
     定义一个XPATH上下文指针xmlXPathContextPtr context，并且使用xmlXPathNewContext函数来初始化这个指针；
     定义一个XPATH对象指针xmlXPathObjectPtr result，并且使用xmlXPathEvalExpression函数来计算Xpath表达式，得到查询结果，将结果存入对象指针中；
     使用result->nodesetval得到节点集合指针，其中包含了所有符合Xpath查询结果的节点；
     使用xmlXPathFreeContext释放上下文指针；
     使用xmlXPathFreeObject释放Xpath对象指针；
     */
    xmlXPathContext *context = xmlXPathNewContext(doc);
    if (context == NULL) {
        return;
    }
    xmlXPathObject *result = xmlXPathEvalExpression((const xmlChar *)("/tr/td"), context);
    if (result == NULL) {
        return;
    }
    if (xmlXPathNodeSetIsEmpty(result->nodesetval)) {
        xmlXPathFreeObject(result);
        return;
    }
    xmlNodeSet *set = result->nodesetval;
    xmlNodePtr *node = set->nodeTab;
    while (node) {
        
    }
    xmlXPathFreeContext(context);
    xmlXPathFreeObject(result);
}

- (void)transcode
{
    /*
     用iconv解决XML中的中文问题
     libxml2中默认的内码是UTF-8，所有使用libxml2进行处理的xml文件，必须首先显式或默认的转换为UTF-8编码才能被处理。
     要在xml中使用中文，就必须能够在UTF-8和GB2312内码（较常用的一种简体中文编码）之间进行转换。
     libxml2提供了默认的内码转换机制，并且在libxml2的Tutorial中有一个例子，事实证实这个例子并不适合用来转换中文。
     
     我们显式的使用ICONV来进行内码转换，libxml2本身也是使用iconv进行转换的。
     iconv是个专门用来进行编码转换的库，基本上支持目前所有常用的编码。他是glibc库的一个部分，常常被用于UNIX系统中。
     本节和xml及libxml2没有太大关系，只是个编码转换方面的问题。
     即从UTF-8转换到GB2312的函数u2g，及反向转换的函数g2u
     */
    NSDictionary *propertyList = @{};
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:propertyList format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    [data writeToFile:@"path" atomically:YES];
    NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
    NSDictionary *de_propertyList =  [NSPropertyListSerialization propertyListWithData:[NSData new] options:NSPropertyListImmutable format:&format error:nil];
    NSLog(@"%@",de_propertyList);
}

//http://www.gnu.org/software/libiconv/
/**
 空的编码方式""等价于"char",它表示依赖与区域相关字符编码。
 如果在tocode后面追加"//TRANSLIT"(eg "utf-8//TRANSLIT"),那么如果一个字符无法被转换，则会自动寻找相似字符进行替换。
 如果追加的是"//IGNORE",则会忽略无法转换的字符。
 注意:1.不支持并发使用,因为调用iconv函数后会修改句柄的状态
     2.返回的句柄是可复用的,但是需要用iconv函数给inbuf传入NULL,修恢复句柄到初始状态
 
 
 @param tocode 要转换到的编码格式
 @param fromcode 源数据编码格式
 @return 如果成功,则返回句柄;如果失败(转换编码不支持 error:EINVAL,通常是写错了),那么就写入errno,返回(iconv_t)(−1)。
 */
iconv_t iconv_open(const char* tocode, const char* fromcode);
/**
 注意:
 1.iconv会修改传入的参数，所以要保存好原始outbuf指针。
 2.如果inbuf中遇到非法字节序列会截断，这时inbuf就指向被截断的第一个字节。一般出现在编码指定错误或者是数据源被截断的时候。比如我们指定gb2312转ut-8，但是数据源里出现阿拉伯字符，这个时候就会发生截断。
 2.如果outbuf空间不足，也会发生截断，不过这种情况相对少见，因为我们程序中会保证输出缓存有足够空间。
 3.另一种情况相对比较“正常”，就是被转的字符集不包含源字符集的字符.比如utf-8到gb2312的转换就很有可能发生这种情况。这时tocode的追加参数就起作用了，iconv会自动进行替换或者忽略。
 
 当inbuf为NULL或者 *inbuf为NULL，但是outbuf不为NULL且 *outbuf不为NULL。
 在这种情况下,iconv函数会尝试将cd的转换状态设置为初始状态，并在 *outbuf处存储相应的移位序列。
 最多 *outbytesleft字节，从 *outbuf开始，将被写入。
 如果输出缓冲区没有更多空间用于该复位序列，errno:E2BIG 函数返回 (size_t)(−1)
 否则，它会增加 *outbuf并减少 *outbytesleft所写入的字节数。
 当inbuf为NULL或 *inbuf为NULL，并且outbuf为NULL或 *outbuf为NULL时. 在这种情况下,iconv函数将cd的转换状态设置为初始状态。
 
 
 iconv函数一次转换一个多字节字符，对于每个字符转换，它会增加 *inbuf和inbytesleft中的转换输入字节数，它会增加* outbuf和* outbytesleft转换后的输出字节数，
 更新cd中包含的转换状态。如果输入的字符编码是有状态的，iconv函数也可以将输入字节序列转换为转换状态的更新而不产生任何输出字节;
 这样的输入被称为移位序列。转换可以停止，原因有四：
 1.遇到了无效的字节序 errno:EILSEQ 函数返回 (size_t)(−1) *inbuf指针会在生下字节序的开头
 2.*inbuf已被完全转化，即*inbytesleft已降至0。在这种情况下iconv返回非可逆转换操作的执行次数。
 3.输入中遇到一个不完整的字节序，输入字节序列在其后面终止。errno:EINVAL 函数返回(size_t)(−1), *inbuf指向不完整的多字节序列的开始。
 4.输出缓冲区不足。errno:E2BIG 函数返回 (size_t)(−1)
 
 errors:
 1.E2BIG *outbuf缓冲区不足
 2.EILSEQ *inbuf 中有无效的字节序
 3.EINVAL *inbuf中有不完整的字节序
 
 @param cd          iconv_open返回的句柄
 @param inbuf       转换完毕后inbuf会指向无法成功转换而被截断的第一个字符，
 @param inbytesleft 传入要转换的源字节长度,在函数结束的时候,代表有多少字符尚未转换,如果全部转换成功则是0
 @param outbuf      传入要输出的字节长度,在函数结束的时候,指向输出缓存的转换后的字符的末尾
 @param outbytesleft 表明输出缓存尚有多少自己剩余
 @return 如果转换成功（没有发生截断），iconv返回的是已经转换的字符(不可逆)总数（也就是被替换或是忽略的字符总数，如果一切正常，应该返回0），如果转换失败，返回-1.
 */
size_t iconv (iconv_t cd, char ** __restrict  inbuf,  size_t * __restrict  inbytesleft,
                          char ** __restrict outbuf,  size_t * __restrict outbytesleft);
/**
 释放句柄资源。
 
 @param cd iconv_open返回的句柄
 @return close成功返回0. 如果出错就设置errno并返回−1.
 */
int iconv_close (iconv_t cd);
- (BOOL)convertString:(char *)buffer
              charset:(const char *)charset
               length:(size_t)length
           to_charset:(const char *)to_charset
           out_buffer:(char *)out_buffer
           out_length:(size_t)out_length
{
    iconv_t cd = iconv_open(to_charset, charset);
    int err = errno;//errno只是保存上一次的失败code,所以要尽快保存下来
    if(cd == (iconv_t)(-1)){
        if (err == EINVAL) {
            printf("The conversion from fromcode to tocode is not supported by the implementation.");
        }
        return NO;
    }
    memset(out_buffer, 0 ,out_length);
    size_t inbytesleft  = length;
    size_t outbytesleft = out_length;
    size_t size = iconv(cd, &buffer, &inbytesleft, &out_buffer, &outbytesleft);
    if (size == -1) {
        return NO;
    }
    iconv_close(cd);
    return 0;
}
- (void)delete:(xmlNode *)curNode
{
    /*
     没有xmlDelNode 或 xmlRemoveNode函数
     将当前节点从文件中断链（unlink），这样本文件就不会再包含这个子节点。
     这样做需要使用一个临时变量来存储断链节点的后续节点，并记得要手动删除断链节点的内存。
     */
    if (!xmlStrcmp(curNode->name, BAD_CAST "newNode1")){
        xmlNodePtr tempNode;
        tempNode = curNode->next;
        xmlUnlinkNode(curNode);
        xmlFreeNode(curNode);
        curNode = tempNode;
        
    }
}
@end
