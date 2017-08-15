//
//  UserListTableViewController.m
//  WilddogVideoQuickStart
//
//  Created by IMacLi on 16/9/13.
//  Copyright © 2016年 liwuyang. All rights reserved.
//

#import "UserListTableViewController.h"

@interface UserListTableViewController ()

@property (nonatomic, strong) NSArray *onlineUsers;

@end

@implementation UserListTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.onlineUsers = [[NSArray alloc] init];
    self.title = @"用户列表";

    // 监听在线用户
    [self setupOnlineUserMonitoring];
    
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.onlineUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = self.onlineUsers[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.selectedUserBlock) {
        [self.navigationController popViewControllerAnimated:YES];
        self.selectedUserBlock(self.onlineUsers[indexPath.row]);
    }
}

#pragma mark - Helper

- (void)setupOnlineUserMonitoring
{
    __weak __typeof__(self) weakSelf = self;
    [self.usersReference observeEventType:WDGDataEventTypeValue withBlock:^(WDGDataSnapshot *snapshot) {
        __strong __typeof__(self) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }

        NSMutableArray *onlineUsers = [[NSMutableArray alloc] init];
        for (WDGDataSnapshot *userSnapshot in snapshot.children) {
            if (![userSnapshot.key isEqualToString:strongSelf.userID]) {
                [onlineUsers addObject:userSnapshot.key];
            }
        }
        strongSelf.onlineUsers = [onlineUsers copy];
        [strongSelf.tableView reloadData];
    }];
}

@end
