//
//  ViewController.m
//  WilddogVideoQuickStart
//
//  Created by IMacLi on 16/9/12.
//  Copyright © 2016年 liwuyang. All rights reserved.
//

#import "ViewController.h"

#import "RoomViewController.h"
#import <WilddogCore/WilddogCore.h>
#import <WilddogAuth/WilddogAuth.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation ViewController

- (IBAction)clickBtn:(id)sender {

    [WDGApp configureWithOptions:[[WDGOptions alloc] initWithSyncURL:[NSString stringWithFormat:@"https://%@.wilddogio.com", self.textField.text]]];

    // 使用VideoSDK前必须经过WilddogAuth身份认证
    __weak __typeof__(self) weakSelf = self;
    [[WDGAuth auth] signInAnonymouslyWithCompletion:^(WDGUser * _Nullable user, NSError * _Nullable error) {
        __strong __typeof__(self) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }

        if (error) {
            NSLog(@"请在控制台为您的AppID开启匿名登录功能，错误信息: %@", error);
            return;
        }

         [strongSelf performSegueWithIdentifier:@"RoomViewController" sender:user];
    }];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    RoomViewController *viewController = (RoomViewController *)[segue destinationViewController];
    viewController.user = sender;
}

@end
