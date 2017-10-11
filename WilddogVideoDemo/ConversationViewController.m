//
//  ConversationViewController.m
//  WilddogVideoDemo
//
//  Created by Hayden on 2017/9/16.
//  Copyright © 2017年 Wilddog. All rights reserved.
//

#import <WilddogCore/WilddogCore.h>
#import <WilddogSync/WilddogSync.h>
#import <WilddogVideoCall/WilddogVideoCall.h>
#import "ConversationViewController.h"
#import "UserListTableViewController.h"

@interface ConversationViewController () <WDGVideoCallDelegate, WDGConversationDelegate, WDGConversationStatsDelegate>

// UI elements
@property (weak, nonatomic) IBOutlet WDGVideoView *localVideoView;
@property (weak, nonatomic) IBOutlet WDGVideoView *remoteVideoView;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet UILabel *wilddogIDLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *localStatsLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *remoteStatsLabel;

// About user list
@property (nonatomic, strong) WDGSyncReference *usersReference;
@property (nonatomic, strong) NSMutableArray *onlineUsers;

// About video conversation
@property (nonatomic, strong) WDGVideoCall *wilddogVideoClient;
@property (nonatomic, strong) WDGLocalStream *localStream;
@property (nonatomic, strong) WDGRemoteStream *remoteStream;
@property (nonatomic, strong) WDGConversation *videoConversation;

// Custom alert view
@property (nonatomic, strong) UIAlertController *foregroundAlert;

@end


@implementation ConversationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    self.wilddogIDLabel.text = self.user.uid;
    
    // 使用 token 初始化 Video Client。
    self.wilddogVideoClient = [WDGVideoCall sharedInstance];
    self.wilddogVideoClient.delegate = self;
    
    // 设置视频流以等比缩放并填充的方式。
    [self setVideoViewDisplayMode];
    
    // 创建本地流并预览
    [self createLocalStream];
    [self previewLocalStream];
    
    // SDK本身不提供管理在线用户的接口，因此建立users节点管理在线用户列表
    self.usersReference = [[[WDGSync sync] reference] child:@"users"];
    [[self.usersReference child:self.user.uid] setValue:@YES];
    [[self.usersReference child:self.user.uid] onDisconnectRemoveValue];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [self clearStatsLabels];
}

- (void)dealloc {
    [self.videoConversation close];
    [self.remoteStream detach:self.remoteVideoView];
    self.remoteStream = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[self.usersReference child:self.user.uid] removeValue];
}

#pragma mark - Action

- (IBAction)switchCamera:(id)sender {
    [self.localStream switchCamera];
    self.localVideoView.mirror = !self.localVideoView.mirror;
}

- (IBAction)toggleVideo:(id)sender {
    self.localStream.videoEnabled = !self.localStream.videoEnabled;
}

- (IBAction)toggleAudio:(id)sender {
    self.localStream.audioEnabled = !self.localStream.audioEnabled;
}

- (IBAction)actionButtonTapped:(id)sender {
    if (self.remoteStream == nil) {
        [self performSegueWithIdentifier:@"UserListTableViewController" sender:nil];
    } else {
        [self.actionButton setTitle:@"邀请用户" forState:UIControlStateNormal];
        [self.actionButton setBackgroundColor:[UIColor colorWithRed:0 green:0.5 blue:1.0 alpha:0.7]];
        [self.videoConversation close];
        [self clearStatsLabels];
        [self.remoteStream detach:self.remoteVideoView];
        self.remoteStream = nil;
        self.videoConversation = nil;
    }
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UserListTableViewController *viewController = (UserListTableViewController *)[segue destinationViewController];
    viewController.userID = self.user.uid;
    viewController.usersReference = self.usersReference;
    
    // 当用户列表选择用户后邀请用户
    __weak __typeof__(self) weakSelf = self;
    viewController.selectedUserBlock = ^(NSString *userID) {
        __strong __typeof__(self) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        [strongSelf callUser:userID];
    };
}

#pragma mark - Call User

- (void)callUser:(NSString *)userID {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"邀请" message:[NSString stringWithFormat:@"正在邀请 %@ 进行视频通话", userID] preferredStyle:UIAlertControllerStyleAlert];
    
    // 采用P2P模式，调用VideoSDK进行邀请
    self.videoConversation = [self.wilddogVideoClient callWithUid:userID localStream:self.localStream data:@"附加信息：你好"];
    self.videoConversation.delegate = self;
    self.videoConversation.statsDelegate = self;
    
    __weak __typeof__(self) weakSelf = self;
    UIAlertAction *cancelInviteAction = [UIAlertAction actionWithTitle:@"取消邀请" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
        __strong __typeof__(self) strongSelf = weakSelf;
        [strongSelf.videoConversation close];
        strongSelf.videoConversation = nil;
        [strongSelf.actionButton setTitle:@"邀请用户" forState:UIControlStateNormal];
        [strongSelf.actionButton setBackgroundColor:[UIColor colorWithRed:0 green:0.5 blue:1.0 alpha:0.7]];
    }];
    [alertController addAction:cancelInviteAction];
    
    [self presentViewController:alertController animated:YES completion:^{
        __strong __typeof__(self) strongSelf = weakSelf;
        if (strongSelf.busyFlag) {
            [alertController dismissViewControllerAnimated:YES completion:nil];
            [strongSelf dismissForegroundAlert];
            strongSelf.busyFlag = NO;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [strongSelf showAlertWithTitle:@"正忙" message:@"对方正忙，请稍后再试"];
            });
        }
    }];
    self.foregroundAlert = alertController;
}

#pragma mark - WDGVideoCallDelegate

- (void)wilddogVideoCall:(WDGVideoCall *)videoCall didReceiveCallWithConversation:(WDGConversation *)conversation data:(NSString *)data {
    conversation.delegate = self;
    conversation.statsDelegate = self;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"%@ 邀请你进行视频通话\n%@", conversation.remoteUid, data] preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *rejectAction = [UIAlertAction actionWithTitle:@"拒绝" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [conversation reject];
    }];
    
    __weak __typeof__(self) weakSelf = self;
    UIAlertAction *acceptAction = [UIAlertAction actionWithTitle:@"接受" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        __strong __typeof__(self) strongSelf = weakSelf;
        
        strongSelf.videoConversation = conversation;
        [strongSelf.videoConversation acceptWithLocalStream:strongSelf.localStream];
        strongSelf.actionButton.enabled = YES;
        [strongSelf.actionButton setTitle:@"结束通话" forState:UIControlStateNormal];
        [strongSelf.actionButton setBackgroundColor:[UIColor colorWithRed:1.0 green:0 blue:0 alpha:0.7]];
    }];
    
    [alertController addAction:rejectAction];
    [alertController addAction:acceptAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
    self.foregroundAlert = alertController;
}


#pragma mark - WDGConversationDelegate

- (void)conversation:(WDGConversation *)conversation didReceiveResponse:(WDGCallStatus)callStatus {
    switch (callStatus) {
        case WDGCallStatusAccepted:
            NSLog(@"Call Accepted!");
            self.actionButton.enabled = YES;
            [self.actionButton setTitle:@"结束通话" forState:UIControlStateNormal];
            [self.actionButton setBackgroundColor:[UIColor colorWithRed:1.0 green:0 blue:0 alpha:0.7]];
            [self dismissForegroundAlert];
            break;
        case WDGCallStatusRejected:
            NSLog(@"Call Rejected!");
            self.videoConversation = nil;
            [self dismissForegroundAlert];
            [self showAlertWithTitle:@"拒绝" message:@"对方拒绝了你的通话请求"];
            break;
        case WDGCallStatusBusy:
            NSLog(@"Call Busy!");
            self.videoConversation = nil;
            self.busyFlag = YES;
            break;
        case WDGCallStatusTimeout:
            NSLog(@"Call Timeout!");
            [self.videoConversation close];
            self.videoConversation = nil;
            [self dismissForegroundAlert];
            [self showAlertWithTitle:@"请求超时" message:@"对方超过30秒未应答"];
            break;
        default:
            break;
    }
}

- (void)conversationDidClosed:(WDGConversation *)conversation {
    NSLog(@"通话关闭");
    if (!self.foregroundAlert) {
        [self showAlertWithTitle:@"通话结束" message:[NSString stringWithFormat:@"Disconnected from: %@", conversation.remoteUid]];
    }
    [self.actionButton setTitle:@"邀请用户" forState:UIControlStateNormal];
    [self.actionButton setBackgroundColor:[UIColor colorWithRed:0 green:0.5 blue:1.0 alpha:0.7]];
    [self.remoteStream detach:self.remoteVideoView];
    self.videoConversation = nil;
    [self dismissForegroundAlert];
    [self clearStatsLabels];
}

- (void)conversation:(WDGConversation *)conversation didReceiveStream:(WDGRemoteStream *)remoteStream {
    // 获得参与者音视频流，将其展示出来
    NSLog(@"receive stream %@ from user %@", remoteStream, conversation.remoteUid);
    self.remoteStream = remoteStream;
    [self.remoteStream attach:self.remoteVideoView];
}

- (void)conversation:(WDGConversation *)conversation didFailedWithError:(NSError *)error {
    NSLog(@"通话错误");
    [self dismissForegroundAlert];
    [self showAlertWithTitle:@"通话错误" message:error.description];
}


#pragma mark - WDGConversationStatsDelegate

- (void)conversation:(WDGConversation *)conversation didUpdateLocalStreamStatsReport:(WDGLocalStreamStatsReport *)report {
    // 显示本地媒体流统计信息
    self.localStatsLabel.text = [NSString stringWithFormat:@"上传: %@", report.description];
}

- (void)conversation:(WDGConversation *)conversation didUpdateRemoteStreamStatsReport:(WDGRemoteStreamStatsReport *)report {
    // 显示远端媒体流统计信息
    self.remoteStatsLabel.text = [NSString stringWithFormat:@"下载: %@", report.description];
}


#pragma mark - Helper

- (void)appWillEnterForegroundNotification:(NSNotification *)notification {
    [[self.usersReference child:self.user.uid] setValue:@YES];
    [[self.usersReference child:self.user.uid] onDisconnectRemoveValue];
}

- (void)setVideoViewDisplayMode {
    self.localVideoView.mirror = YES;
    self.localVideoView.contentMode = UIViewContentModeScaleAspectFill;
    self.remoteVideoView.contentMode = UIViewContentModeScaleAspectFill;
}

- (void)createLocalStream {
    WDGLocalStreamOptions *localStreamOptions = [[WDGLocalStreamOptions alloc] init];
    localStreamOptions.shouldCaptureAudio = YES;
    localStreamOptions.dimension = WDGVideoDimensions360p;
    self.localStream = [[WDGLocalStream alloc] initWithOptions:localStreamOptions];
}

- (void)previewLocalStream {
    if (self.localStream != nil) {
        [self.localStream attach:self.localVideoView];
    }
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)dismissForegroundAlert {
    [self.foregroundAlert dismissViewControllerAnimated:YES completion:nil];
    self.foregroundAlert = nil;
}

- (void)clearStatsLabels {
    [self.localStatsLabel setText:@""];
    [self.remoteStatsLabel setText:@""];
}

@end
