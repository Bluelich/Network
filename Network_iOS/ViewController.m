//
//  ViewController.m
//  Network_iOS
//
//  Created by zhouqiang on 14/12/2017.
//

#import "ViewController.h"
#import "Reachability.h"
#import "Test.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 20, 0, 0);
    [Reachability.shared setNetworkStatusChangedBlock:^(NetworkStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *currentStatus = [NSString stringWithFormat:@"%@\n\nProxy:\n%@",NSStringFromNetworkStatus(status),proxy_test()];
            if (self.textView.text.length) {
                currentStatus = [self.textView.text stringByAppendingFormat:@"\n\n-----------------\n%@",currentStatus];
            }
            self.textView.text = currentStatus;
            [self.textView scrollRectToVisible:[self.textView caretRectForPosition:self.textView.endOfDocument] animated:YES];
        });
    }];
    socket_connect(@"apple.com");
}
@end
