//
//  ViewController.m
//  Network_iOS
//
//  Created by zhouqiang on 14/12/2017.
//

#import "ViewController.h"
#import "Reachability.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.label.text = NSStringFromNetworkStatus(Reachability.shared.status);
    [Reachability.shared setNetworkStatusChangedBlock:^(NetworkStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.label.text = NSStringFromNetworkStatus(status);
        });
    }];
    
}
@end
