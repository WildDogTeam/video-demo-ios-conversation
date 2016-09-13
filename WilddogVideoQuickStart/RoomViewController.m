//
//  RoomViewController.m
//  WilddogVideoQuickStart
//
//  Created by IMacLi on 16/9/12.
//  Copyright © 2016年 liwuyang. All rights reserved.
//

#import "RoomViewController.h"
#import <WilddogSync/WilddogSync.h>
#import <WilddogVideo/WilddogVideo.h>
#import "UserListTableViewController.h"
@interface RoomViewController ()<WDGVideoClientDelegate, WDGVideoConversationDelegate>

@property(nonatomic, strong) WDGSyncReference *wilddog;
@property(nonatomic, strong)WDGVideoClient *wilddogVideoClient;
@property(nonatomic, strong)WDGVideoLocalStream *localStream;
@property(nonatomic, strong)WDGVideoConversation *videoConversation;
@property (weak, nonatomic) IBOutlet WDGVideoView *localVideoView;
@property(nonatomic, strong) WDGVideoRemoteStream *remoteStream;
@property (weak, nonatomic) IBOutlet WDGVideoView *remoteVideoView;
@property(nonatomic, strong)NSString *myUserID;
@property(nonatomic, strong)NSMutableArray *onlineUsers;
@property (weak, nonatomic) IBOutlet UIButton *userListBtn;
@property (weak, nonatomic) IBOutlet UILabel *uidLab;

@end

@implementation RoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.myUserID = self.wDGUser.uid;
    self.wilddog = [[WDGSync sync] reference];

    self.uidLab.text = self.myUserID;
    [self setupWilddogVideoClient];

}

- (IBAction)clickUserList:(id)sender {
    if (!self.remoteStream) {
        [self performSegueWithIdentifier:@"UserListTableViewController" sender:nil];
    } else {
        self.userListBtn.titleLabel.text = @"用户列表";
        [self.videoConversation disconnect];
        [self.remoteStream detach:self.remoteVideoView];
        self.videoConversation = nil;
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    UserListTableViewController *viewController = (UserListTableViewController *)[segue destinationViewController];
    viewController.userID = self.myUserID;
    viewController.wilddog = self.wilddog;
    __block RoomViewController *strongSelf = self;
    viewController.selectedUserBlock = ^(NSString *userID) {

        [strongSelf inviteAUser:userID];

    };
}

-(void)setupWilddogVideoClient {

    WDGSyncReference *userWilddog = [[self.wilddog child:@"users"] child:self.myUserID];
    [userWilddog setValue:@YES];
    [userWilddog onDisconnectRemoveValue];

    self.wilddogVideoClient = [[WDGVideoClient alloc] initWithSyncReference:self.wilddog user:self.wDGUser];
    self.wilddogVideoClient.delegate = self;

    [self startPreview];

     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

-(void)appWillEnterForegroundNotification:(NSNotification *)notification {
    WDGSyncReference *userWilddog = [[self.wilddog child:@"users"] child:self.myUserID];
    [userWilddog setValue:@YES];
    [userWilddog onDisconnectRemoveValue];
}

-(void)startPreview {

#if !TARGET_IPHONE_SIMULATOR
    WDGVideoLocalStreamConfiguration *configuration = [[WDGVideoLocalStreamConfiguration alloc] initWithVideoOption:WDGVideoConstraintsStandard16x9 audioOn:YES];
    self.localStream = [self.wilddogVideoClient localStreamWithConfiguration:configuration];
#else
    //diable camera controls if on the simulator
#endif
    if (self.localStream) {
        [self.localStream attach:self.localVideoView];
    }
    
}

#pragma mark - Invite a User

-(void)inviteAUser:(NSString *)userID {

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"邀请" message:[NSString stringWithFormat:@"正在邀请 %@ 进行视频通话", userID] preferredStyle:UIAlertControllerStyleAlert];

    __block RoomViewController *strongSelf = self;
    WDGVideoOutgoingInvite *outgoingInvitation = [self.wilddogVideoClient inviteUser:userID localStream:self.localStream conversationMode:WDGVideoConversationModeBasic completion:^(WDGVideoConversation * _Nullable conversation, NSError * _Nullable error) {
        [alertController dismissViewControllerAnimated:YES completion:nil];
        if (conversation) {
            self.videoConversation = conversation;
            self.videoConversation.delegate = self;
        } else {
            NSString *errorMessage = [NSString stringWithFormat:@"邀请用户错误(%@): %@", userID, [error localizedDescription]];
            NSLog(@"%@",errorMessage);

            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"视频通话邀请被对方拒绝" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:okAction];
            [strongSelf presentViewController:alertController animated:YES completion:nil];
        }
    }];

    UIAlertAction *cancelInviteAction = [UIAlertAction actionWithTitle:@"取消邀请" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [outgoingInvitation cancel];
    }];
    [alertController addAction:cancelInviteAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Display an Error

- (void) displayErrorMessage:(NSString*)errorMessage {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"视频通话邀请被对方拒绝" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma -mark WDGVideoClientDelegate

- (void)wilddogVideoClient:(WDGVideoClient *)videoClient didReceiveInvite:(WDGVideoIncomingInvite *)invite {

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"%@ 邀请你进行视频通话", invite.fromUserID] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *rejectAction = [UIAlertAction actionWithTitle:@"拒绝" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [invite reject];
    }];

    UIAlertAction *acceptAction = [UIAlertAction actionWithTitle:@"接受" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        __block RoomViewController *strongSelf = self;
        [invite acceptWithCompletionHandler:^(WDGVideoConversation * _Nullable conversation, NSError * _Nullable error) {
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

#pragma -mark WDGVideoConversationDelegate

- (void)conversation:(WDGVideoConversation *)conversation didConnectParticipant:(WDGVideoParticipant *)participant {

    dispatch_async(dispatch_get_main_queue(), ^{
        self.remoteStream  = participant.stream;
        [self.remoteStream attach:self.remoteVideoView];
        self.userListBtn.titleLabel.text = @"挂断";
    });

}

- (void)conversation:(WDGVideoConversation *)conversation didFailToConnectParticipant:(WDGVideoParticipant *)participant error:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"通话失败" message:nil preferredStyle:UIAlertControllerStyleAlert];
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



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
