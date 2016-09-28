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
@property (weak, nonatomic) IBOutlet UIButton *userListBtn;
@property (weak, nonatomic) IBOutlet UILabel *uidLab;

@property (nonatomic, strong) WDGSyncReference *wilddog;
@property (nonatomic, strong) WDGVideoClient *wilddogVideoClient;
@property (nonatomic, strong) WDGVideoLocalStream *localStream;
@property (nonatomic, strong) WDGVideoRemoteStream *remoteStream;
@property (nonatomic, strong) WDGVideoConversation *videoConversation;

@property (nonatomic, strong) NSString *myUserID;
@property (nonatomic, strong) NSMutableArray *onlineUsers;

@end

@implementation RoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.myUserID = self.wDGUser.uid;
    self.wilddog = [[WDGSync sync] reference];

    self.uidLab.text = self.myUserID;
    [self setupWilddogVideoClient];
}

#pragma mark - Action

- (IBAction)clickUserList:(id)sender {
    if (!self.remoteStream) {
        [self performSegueWithIdentifier:@"UserListTableViewController" sender:nil];
    } else {
        self.userListBtn.titleLabel.text = @"用户列表";
        [self.videoConversation disconnect];
        [self.remoteStream detach:self.remoteVideoView];
        self.remoteStream = nil;
        self.videoConversation = nil;
    }
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    UserListTableViewController *viewController = (UserListTableViewController *)[segue destinationViewController];
    viewController.userID = self.myUserID;
    viewController.wilddog = self.wilddog;
    __block RoomViewController *strongSelf = self;
    // 当用户列表选择用户后邀请用户
    viewController.selectedUserBlock = ^(NSString *userID) {

        [strongSelf inviteAUser:userID];

    };
}

#pragma mark - Helper

- (void)setupWilddogVideoClient {
    // 认证成功，初始化Client
    self.wilddogVideoClient = [[WDGVideoClient alloc] initWithSyncReference:self.wilddog user:self.wDGUser];
    self.wilddogVideoClient.delegate = self;

    // 创建本地流并预览
    [self createLocalStream];
    [self previewLocalStream];

    // SDK本身不提供管理在线用户的接口，因此建立users节点管理在线用户列表
    WDGSyncReference *userWilddog = [[self.wilddog child:@"users"] child:self.myUserID];
    [userWilddog setValue:@YES];
    [userWilddog onDisconnectRemoveValue];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)appWillEnterForegroundNotification:(NSNotification *)notification {
    WDGSyncReference *userWilddog = [[self.wilddog child:@"users"] child:self.myUserID];
    [userWilddog setValue:@YES];
    [userWilddog onDisconnectRemoveValue];
}

- (void)createLocalStream {
    WDGVideoLocalStreamConfiguration *configuration = [[WDGVideoLocalStreamConfiguration alloc] initWithVideoOption:WDGVideoConstraintsStandard audioOn:YES];
    self.localStream = [self.wilddogVideoClient localStreamWithConfiguration:configuration];
}

- (void)previewLocalStream {
    if (self.localStream) {
        [self.localStream attach:self.localVideoView];
    }
}

#pragma mark - Invite User

- (void)inviteAUser:(NSString *)userID {

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"邀请" message:[NSString stringWithFormat:@"正在邀请 %@ 进行视频通话", userID] preferredStyle:UIAlertControllerStyleAlert];

    // 采用P2P模式，调用VideoSDK进行邀请
    __block RoomViewController *strongSelf = self;
    WDGVideoOutgoingInvite *outgoingInvitation = [self.wilddogVideoClient inviteUser:userID localStream:self.localStream conversationMode:WDGVideoConversationModeP2P completion:^(WDGVideoConversation * _Nullable conversation, NSError * _Nullable error) {
        [alertController dismissViewControllerAnimated:YES completion:nil];
        if (conversation) {
            self.videoConversation = conversation;
            self.videoConversation.delegate = self;
        } else {
            NSString *errorMessage = [NSString stringWithFormat:@"邀请用户错误(%@): %@", userID, [error localizedDescription]];
            NSLog(@"%@",errorMessage);

            [strongSelf displayErrorMessage:@"视频通话邀请被对方拒绝"];
        }
    }];

    UIAlertAction *cancelInviteAction = [UIAlertAction actionWithTitle:@"取消邀请" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [outgoingInvitation cancel];
    }];
    [alertController addAction:cancelInviteAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Display Error

- (void)displayErrorMessage:(NSString *)errorMessage {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
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

- (void)wilddogVideoClient:(WDGVideoClient *)videoClient inviteDidCancel:(WDGVideoIncomingInvite *)invite {

}

#pragma mark - WDGVideoConversationDelegate


- (void)conversation:(WDGVideoConversation *)conversation didConnectParticipant:(WDGVideoParticipant *)participant {
    // 参与者成功加入会话，将参与者的视频流展示出来
    dispatch_async(dispatch_get_main_queue(), ^{
        self.remoteStream = participant.stream;
        [self.remoteStream attach:self.remoteVideoView];
        self.userListBtn.titleLabel.text = @"挂断";
    });
}

- (void)conversation:(WDGVideoConversation *)conversation didFailToConnectParticipant:(WDGVideoParticipant *)participant error:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"连接失败" message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)conversation:(WDGVideoConversation *)conversation didDisconnectParticipant:(WDGVideoParticipant *)participant {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"通话结束" message:[NSString stringWithFormat:@"Disconnected from: %@",participant.userID] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.remoteStream detach:self.remoteVideoView];
        self.videoConversation = nil;
    });
}

@end
