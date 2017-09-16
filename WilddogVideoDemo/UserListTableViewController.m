//
//  UserListTableTableViewController.m
//  WilddogVideoDemo
//
//  Created by Hayden on 2017/9/16.
//  Copyright © 2017年 Wilddog. All rights reserved.
//

#import "UserListTableViewController.h"

@interface UserListTableViewController ()

@property (nonatomic, strong) NSArray *onlineUsers;

@end

@implementation UserListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 监听在线用户
    self.onlineUsers = [[NSArray alloc] init];
    [self setupOnlineUserMonitoring];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.onlineUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = self.onlineUsers[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Hello");
    if (self.selectedUserBlock) {
        [self.navigationController popViewControllerAnimated:YES];
        self.selectedUserBlock(self.onlineUsers[indexPath.row]);
    }
}

#pragma mark - Helper

- (void)setupOnlineUserMonitoring {
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
