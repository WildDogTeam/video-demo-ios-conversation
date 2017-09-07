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

@property (weak, nonatomic) IBOutlet UITextField *videoField;
@property (weak, nonatomic) IBOutlet UITextField *syncField;
@property (strong, nonatomic) NSString *token;
@property (strong, nonatomic) NSString *appId;

@end

@implementation LoginViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
//    在这里写入默认的videoId以及syncId;
    self.videoField.text =@"";
    self.syncField.text =@"";
}

- (IBAction)clickBtn:(id)sender
{
    if(self.videoField.text.length ==0 || self.syncField.text.length==0){
        NSLog(@"请填写videoId及syncId");
        return;
    }
    self.appId = self.videoField.text;
    
    [WDGApp configureWithOptions:[[WDGOptions alloc] initWithSyncURL:[NSString stringWithFormat:@"https://%@.wilddogio.com", self.syncField.text]]];

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
