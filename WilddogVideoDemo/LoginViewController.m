//
//  LoginViewController.m
//  WilddogVideoDemo
//
//  Created by Hayden on 2017/9/16.
//  Copyright © 2017年 Wilddog. All rights reserved.
//

#import <WilddogCore/WilddogCore.h>
#import <WilddogAuth/WilddogAuth.h>
#import "LoginViewController.h"
#import "ConversationViewController.h"

@interface LoginViewController ()

@property (strong, nonatomic) NSString *token;
@property (strong, nonatomic) NSString *appId;

@end

@implementation LoginViewController

- (IBAction)clickBtn:(id)sender {
    
    // Set Video AppId.
    self.appId = @"wd4824959511jedimo";
    
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ConversationViewController *destinationVC = (ConversationViewController *)[segue destinationViewController];
    destinationVC.user = sender;
    destinationVC.token = self.token;
    destinationVC.appId = self.appId;
}

@end
