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
@property (nonatomic,strong) WDGAuth *wilddogAuth;

@end

@implementation ViewController

- (IBAction)clickBtn:(id)sender {
    // 这个路径是VideoSDK的交互路径，WilddogVideo可换成自定义路径
    // 但采用Server-based模式时需要保证该交互路径和控制面板中的交互路径一致
    [WDGApp configureWithOptions:[[WDGOptions alloc] initWithSyncURL:[NSString stringWithFormat:@"https://%@.wilddogio.com/WilddogVideo", self.textField.text]]];

    self.wilddogAuth = [WDGAuth auth];

    // 使用VideoSDK前必须经过WilddogAuth身份认证
    [self.wilddogAuth signInAnonymouslyWithCompletion:^(WDGUser * _Nullable user, NSError * _Nullable error) {
        if (error) {
            NSLog(@"请在控制台为您的AppID开启匿名登录功能，错误信息: %@", error.localizedDescription);
            return ;
        }

         [self performSegueWithIdentifier:@"RoomViewController" sender:user];
    }];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    RoomViewController *viewController = (RoomViewController *)[segue destinationViewController];
    viewController.wDGUser = sender;
    viewController.appid = self.textField.text;

}

@end
