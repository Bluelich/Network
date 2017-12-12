//
//  MultipeerConnectivityViewController.m
//  NetWork
//
//  Created by zhouqiang on 12/12/2017.
//  Copyright © 2017 Bluelich. All rights reserved.
//

#import "MultipeerConnectivityViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface MultipeerConnectivityViewController ()
<
NSNetServiceDelegate,
MCNearbyServiceAdvertiserDelegate,
MCAdvertiserAssistantDelegate,
MCNearbyServiceBrowserDelegate,
MCBrowserViewControllerDelegate,
MCSessionDelegate
>
@property (nonatomic,strong) MCSession *session;
@end

@implementation MultipeerConnectivityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /*
     init session
     startAdvertisingPeer
     browser:foundPeer:withDiscoveryInfo:
     invitePeer:toSession:withContext:timeout
     advertiser:didReceiveInvitationFromPeer:withContext:invitationHandler:
     session:didReceiveCertificatte:fromPeer:
     session:peer:didChangeState:
     */
    MCPeerID *peerID = [[MCPeerID alloc] initWithDisplayName:@"displayName"];
    self.session = [[MCSession alloc] initWithPeer:peerID securityIdentity:@[] encryptionPreference:MCEncryptionNone];
    self.session.delegate = self;
    [self.session connectPeer:peerID withNearbyConnectionData:[NSData data]];
    NSError *error = nil;
    if (![self.session sendData:[NSData data] toPeers:@[peerID] withMode:MCSessionSendDataReliable error:&error]) {
        printf("error:%s",error.description.UTF8String);
        [self.session disconnect];
    }
    NSProgress *progress = [self.session sendResourceAtURL:[NSURL fileURLWithPath:@"a.txt"] withName:@"a text file" toPeer:peerID withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            printf("error:%s",error.description.UTF8String);
        }
    }];
    double pr = progress.completedUnitCount / (double)progress.totalUnitCount;
    printf("pr:%lf",pr);
    
    MCAdvertiserAssistant   *assistant = [[MCAdvertiserAssistant alloc] initWithServiceType:@"bluelich-test" discoveryInfo:@{@"key":@"value"} session:self.session];
    assistant.delegate = self;
    [assistant start];
    [assistant stop];
    MCNearbyServiceBrowser  *nsb = [[MCNearbyServiceBrowser alloc] initWithPeer:peerID serviceType:@"bluelich-test"];
    nsb.delegate = self;
    [nsb startBrowsingForPeers];
    [nsb stopBrowsingForPeers];
    MCBrowserViewController *vc = [[MCBrowserViewController alloc] initWithBrowser:nsb session:self.session];
    vc.delegate = self;
    
    MCNearbyServiceAdvertiser *nsa = [[MCNearbyServiceAdvertiser alloc] initWithPeer:peerID discoveryInfo:@{} serviceType:@"bluelich.-test"];
    nsa.delegate = self;
    [nsa startAdvertisingPeer];
    [nsa stopAdvertisingPeer];
    
}
- (void)            advertiser:(MCNearbyServiceAdvertiser *)advertiser
  didReceiveInvitationFromPeer:(MCPeerID *)peerID
                   withContext:(nullable NSData *)context
             invitationHandler:(void (^)(BOOL accept, MCSession * __nullable session))invitationHandler
{
    printf("Incoming invitation request.  Call the invitationHandler block with YES and a valid session to connect the inviting peer to the session.");
    invitationHandler(YES,self.session);
}
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    printf("Advertising did not start due to an error:%s",error.description.UTF8String);
}
- (void)advertiserAssistantWillPresentInvitation:(MCAdvertiserAssistant *)advertiserAssistant
{
    printf("An invitation will be presented to the user.");
}
- (void)advertiserAssistantDidDismissInvitation:(MCAdvertiserAssistant *)advertiserAssistant
{
    printf("An invitation was dismissed from screen.");
}
- (void)        browser:(MCNearbyServiceBrowser *)browser
              foundPeer:(MCPeerID *)peerID
      withDiscoveryInfo:(nullable NSDictionary<NSString *, NSString *> *)info
{
    printf("Found a nearby advertising peer.");
    [browser invitePeer: peerID toSession:self.session withContext:nil timeout:30];
}
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    printf("A nearby peer has stopped advertising.");
}
- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    printf("Browsing did not start due to an error.");
}
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    printf("Done button Notifies the delegate, when the user taps the done button.");
}
- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    printf("Cancel button Notifies delegate that the user taps the cancel button.");
}
- (BOOL)browserViewController:(MCBrowserViewController *)browserViewController
      shouldPresentNearbyPeer:(MCPeerID *)peerID
            withDiscoveryInfo:(nullable NSDictionary<NSString *, NSString *> *)info
{
    printf("Notifies delegate that a peer was found;\
           discoveryInfo can be used to determine whether the peer should be presented to the user,\
           and the delegate should return a YES if the peer should be presented;\
           this method is optional,\
           if not implemented every nearby peer will be presented to the user.");
    return YES;
}
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    printf("Remote peer changed state:");
    switch (state) {
        case MCSessionStateNotConnected:
            printf("NotConnected");
            break;
        case MCSessionStateConnecting:
            printf("Connecting");
            break;
        case MCSessionStateConnected:
            printf("Connected");
            break;
    }
}
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    printf("Received data from remote peer.");
}
- (void)    session:(MCSession *)session
   didReceiveStream:(NSInputStream *)stream
           withName:(NSString *)streamName
           fromPeer:(MCPeerID *)peerID
{
    printf("Received a byte stream from remote peer.");
}
- (void)                    session:(MCSession *)session
  didStartReceivingResourceWithName:(NSString *)resourceName
                           fromPeer:(MCPeerID *)peerID
                       withProgress:(NSProgress *)progress
{
    printf("Start receiving a resource from remote peer.");
}
- (void)                    session:(MCSession *)session
 didFinishReceivingResourceWithName:(NSString *)resourceName
                           fromPeer:(MCPeerID *)peerID
                              atURL:(nullable NSURL *)localURL
                          withError:(nullable NSError *)error
{
    printf("Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox.");
}
@end
