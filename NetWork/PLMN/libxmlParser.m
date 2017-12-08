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
}
 -(void)createXML
{
    xmlDoc  *doc  = xmlNewDoc(BAD_CAST("1.0"));
    xmlNode *root = xmlNewNode(NULL, BAD_CAST"root");
    xmlDocSetRootElement(doc, root);
    for (int i = 0; i < 10; i++) {
        char *nodeName = nil;
        snprintf(nodeName, 1, "newNode %d",i);
        char *nodeContent = nil;
        snprintf(nodeContent, 1, "newNode content %d",i);
        xmlNewTextChild(root, NULL, BAD_CAST nodeName, BAD_CAST nodeContent);
    }
}
@end
