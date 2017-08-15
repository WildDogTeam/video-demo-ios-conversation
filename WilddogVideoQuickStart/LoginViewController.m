//
//  ViewController.m
//  WilddogVideoQuickStart
//
//  Created by IMacLi on 16/9/12.
//  Copyright © 2016年 liwuyang. All rights reserved.
//

#import <WilddogCore/WilddogCore.h>
#import <WilddogAuth/WilddogAuth.h>
#import "LoginViewController.h"
#import "RoomViewController.h"

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) NSString *token;
@property (strong, nonatomic) NSString *appId;

@end

@implementation LoginViewController

- (IBAction)clickBtn:(id)sender
{
    self.appId = @"wd4824959511jedimo";
    if (![self.textField.text isEqualToString:@""]) {
        self.appId = self.textField.text;
    }
    
    [WDGApp configureWithOptions:[[WDGOptions alloc] initWithSyncURL:[NSString stringWithFormat:@"https://%@.wilddogio.com", self.appId]]];

    // 使用VideoSDK前必须经过WilddogAuth身份认证
    [[WDGAuth auth] signOut:nil];

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
        [user getTokenWithCompletion:^(NSString * _Nullable idToken, NSError * _Nullable error) {
            strongSelf.token = idToken;
        }];
        
        [strongSelf performSegueWithIdentifier:@"RoomViewController" sender:user];
    }];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    RoomViewController *destinationVC = (RoomViewController *)[segue destinationViewController];
    destinationVC.user = sender;
    destinationVC.token = self.token;
    destinationVC.appId = self.appId;
}

@end
