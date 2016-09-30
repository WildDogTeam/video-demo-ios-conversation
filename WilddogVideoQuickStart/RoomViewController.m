//
//  RoomViewController.m
//  WilddogVideoQuickStart
//
//  Created by IMacLi on 16/9/12.
//  Copyright © 2016年 liwuyang. All rights reserved.
//

#import <WilddogSync/WilddogSync.h>
#import <WilddogVideo/WilddogVideo.h>

#import "RoomViewController.h"
#import "UserListTableViewController.h"

@interface RoomViewController ()<WDGVideoClientDelegate, WDGVideoConversationDelegate>

@property (weak, nonatomic) IBOutlet WDGVideoView *localVideoView;
@property (weak, nonatomic) IBOutlet WDGVideoView *remoteVideoView;
@property (weak, nonatomic) IBOutlet UIButton *userListButton;
@property (weak, nonatomic) IBOutlet UILabel *uidLabel;

@property (nonatomic, strong) WDGSyncReference *syncReference;
@property (nonatomic, strong) WDGVideoClient *wilddogVideoClient;
@property (nonatomic, strong) WDGVideoLocalStream *localStream;
@property (nonatomic, strong) WDGVideoRemoteStream *remoteStream;
@property (nonatomic, strong) WDGVideoConversation *videoConversation;

@property (nonatomic, strong) NSMutableArray *onlineUsers;

@end

@implementation RoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 这个路径是VideoSDK的交互路径，WilddogVideo可换成自定义路径
    // 但采用Server-based模式时需要保证该交互路径和控制面板中的交互路径一致
    self.syncReference = [[[WDGSync sync] reference] child:@"wilddog"];

    self.uidLabel.text = self.user.uid;

    // 认证成功，初始化Client
    self.wilddogVideoClient = [[WDGVideoClient alloc] initWithSyncReference:self.syncReference user:self.user];
    self.wilddogVideoClient.delegate = self;

    // 创建本地流并预览
    [self createLocalStream];
    [self previewLocalStream];

    self.localVideoView.contentMode = UIViewContentModeScaleAspectFill;
    self.remoteVideoView.contentMode = UIViewContentModeScaleAspectFill;

    // SDK本身不提供管理在线用户的接口，因此建立users节点管理在线用户列表
    WDGSyncReference *userWilddog = [[self.syncReference child:@"users"] child:self.user.uid];
    [userWilddog setValue:@YES];
    [userWilddog onDisconnectRemoveValue];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

#pragma mark - Action

- (IBAction)clickUserList:(id)sender {
    if (self.remoteStream == nil) {
        [self performSegueWithIdentifier:@"UserListTableViewController" sender:nil];
    } else {
        self.userListButton.titleLabel.text = @"用户列表";
        [self.videoConversation disconnect];
        [self.remoteStream detach:self.remoteVideoView];
        self.remoteStream = nil;
        self.videoConversation = nil;
    }
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UserListTableViewController *viewController = (UserListTableViewController *)[segue destinationViewController];
    viewController.userID = self.user.uid;
    viewController.syncReference = self.syncReference;

    // 当用户列表选择用户后邀请用户
    __weak __typeof__(self) weakSelf = self;
    viewController.selectedUserBlock = ^(NSString *userID) {
        __strong __typeof__(self) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }

        [strongSelf inviteUser:userID];
    };
}

#pragma mark - Invite User

- (void)inviteUser:(NSString *)userID {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"邀请" message:[NSString stringWithFormat:@"正在邀请 %@ 进行视频通话", userID] preferredStyle:UIAlertControllerStyleAlert];

    // 采用P2P模式，调用VideoSDK进行邀请
    __weak __typeof__(self) weakSelf = self;
    WDGVideoOutgoingInvite *outgoingInvitation = [self.wilddogVideoClient inviteUser:userID localStream:self.localStream conversationMode:WDGVideoConversationModeP2P completion:^(WDGVideoConversation *conversation, NSError *error) {
        __strong __typeof__(self) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }

        [alertController dismissViewControllerAnimated:YES completion:nil];

        if (conversation != nil) {
            self.videoConversation = conversation;
            self.videoConversation.delegate = self;
        } else {
            NSString *errorMessage = [NSString stringWithFormat:@"邀请用户错误(%@): %@", userID, [error localizedDescription]];
            NSLog(@"%@",errorMessage);

            [strongSelf showAlertWithTitle:@"提示" message:errorMessage];
        }
    }];

    UIAlertAction *cancelInviteAction = [UIAlertAction actionWithTitle:@"取消邀请" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [outgoingInvitation cancel];
    }];
    [alertController addAction:cancelInviteAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - WDGVideoClientDelegate

- (void)wilddogVideoClient:(WDGVideoClient *)videoClient didReceiveInvite:(WDGVideoIncomingInvite *)invite {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"%@ 邀请你进行视频通话", invite.fromUserID] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *rejectAction = [UIAlertAction actionWithTitle:@"拒绝" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [invite reject];
    }];

    UIAlertAction *acceptAction = [UIAlertAction actionWithTitle:@"接受" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        __block RoomViewController *strongSelf = self;
        [invite acceptWithCompletion:^(WDGVideoConversation * _Nullable conversation, NSError * _Nullable error) {
            if (error) {
                NSLog(@"error: %@", [error localizedDescription]);
                return ;
            }

            strongSelf.videoConversation = conversation;
            strongSelf.videoConversation.delegate = self;
        }];
    }];

    [alertController addAction:rejectAction];
    [alertController addAction:acceptAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - WDGVideoConversationDelegate

- (void)conversation:(WDGVideoConversation *)conversation didConnectParticipant:(WDGVideoParticipant *)participant {
    // 参与者成功加入会话，将参与者的视频流展示出来
    self.remoteStream = participant.stream;
    [self.remoteStream attach:self.remoteVideoView];
    self.userListButton.titleLabel.text = @"挂断";
}

- (void)conversation:(WDGVideoConversation *)conversation didFailToConnectParticipant:(WDGVideoParticipant *)participant error:(NSError *)error {
    [self showAlertWithTitle:@"连接失败" message:@""];

    self.videoConversation = nil;
}

- (void)conversation:(WDGVideoConversation *)conversation didDisconnectParticipant:(WDGVideoParticipant *)participant {
    [self showAlertWithTitle:@"通话结束" message:[NSString stringWithFormat:@"Disconnected from: %@",participant.userID]];

    [self.remoteStream detach:self.remoteVideoView];
    self.videoConversation = nil;
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Helper

- (void)appWillEnterForegroundNotification:(NSNotification *)notification {
    WDGSyncReference *userWilddog = [[self.syncReference child:@"users"] child:self.user.uid];
    [userWilddog setValue:@YES];
    [userWilddog onDisconnectRemoveValue];
}

- (void)createLocalStream {
    WDGVideoLocalStreamConfiguration *configuration = [[WDGVideoLocalStreamConfiguration alloc] initWithVideoOption:WDGVideoConstraintsStandard audioOn:YES];
    self.localStream = [self.wilddogVideoClient localStreamWithConfiguration:configuration];
}

- (void)previewLocalStream {
    if (self.localStream != nil) {
        [self.localStream attach:self.localVideoView];
    }
}

@end
