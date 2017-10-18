//
//  LoginViewController.m
//  WilddogVideoDemo
//
//  Created by Hayden on 2017/9/16.
//  Copyright © 2017年 Wilddog. All rights reserved.
//

#import <WilddogCore/WilddogCore.h>
#import <WilddogAuth/WilddogAuth.h>
#import <WilddogVideoCall/WilddogVideoCall.h>
#import "LoginViewController.h"
#import "ConversationViewController.h"

@interface LoginViewController ()

@property (strong, nonatomic) NSString *token;
@property (strong, nonatomic) NSString *videoAppId;
@property (strong, nonatomic) NSString *syncAppId;
@property (weak, nonatomic) IBOutlet UISegmentedControl *resolutionRatio;

@end

@implementation LoginViewController

- (IBAction)clickBtn:(id)sender {
    
    // Set AppId.
    self.syncAppId = @"wd4548698313swfjcn";
    self.videoAppId = @"wd4824959511jedimo";
    
    [WDGApp configureWithOptions:[[WDGOptions alloc] initWithSyncURL:[NSString stringWithFormat:@"https://%@.wilddogio.com", self.syncAppId]]];
    
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
            [[WDGVideoInitializer sharedInstance] configureWithVideoAppId:self.videoAppId token:idToken];
        }];
        
        [strongSelf performSegueWithIdentifier:@"RoomViewController" sender:user];
    }];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ConversationViewController *destinationVC = (ConversationViewController *)[segue destinationViewController];
    destinationVC.user = sender;
    destinationVC.token = self.token;
    destinationVC.appId = self.videoAppId;
    switch (self.resolutionRatio.selectedSegmentIndex) {
        case 0:
            destinationVC.resolutionRatio = WDGVideoDimensions360p;
            break;
        case 1:
            destinationVC.resolutionRatio = WDGVideoDimensions480p;
            break;
        case 2:
            destinationVC.resolutionRatio = WDGVideoDimensions720p;
            break;
        default:
            destinationVC.resolutionRatio = WDGVideoDimensions360p;
            break;
    }
}

@end
