//
//  UserListTableViewController.m
//  WilddogVideoQuickStart
//
//  Created by IMacLi on 16/9/13.
//  Copyright © 2016年 liwuyang. All rights reserved.
//

#import "UserListTableViewController.h"
#import "UserTableViewCell.h"
@interface UserListTableViewController ()
@property(nonatomic, strong)NSMutableArray *onlineUsers;

@end

@implementation UserListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.onlineUsers = [@[] mutableCopy];
    self.title = @"用户列表";
    [self setupOnlineUserMonitoring];
    
}

-(void)setupOnlineUserMonitoring {

    __block UserListTableViewController *strongSelf = self;
    [[self.wilddog child:@"users"] observeSingleEventOfType:WDGDataEventTypeValue withBlock:^(WDGDataSnapshot * _Nonnull snapshot) {

        NSDictionary *userDict = snapshot.value;
        for (NSString *userID in userDict.allKeys) {
            if (![userID isEqualToString:self.userID]) {
                [strongSelf.onlineUsers addObject:userID];
            }
        }
        [strongSelf.tableView reloadData];

    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma -mark UITableViewDataSource

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *cellIdentify = @"userCell";
    UserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentify];
    cell.titleLab.text = self.onlineUsers[indexPath.row];
    __block UserListTableViewController *strongSelf = self;
    cell.clickInviteUserBlock = ^(NSString *title) {
        if (strongSelf.selectedUserBlock) {
            [strongSelf.navigationController popViewControllerAnimated:YES];
            strongSelf.selectedUserBlock(title);
        }
    };

    return cell;
}


-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.onlineUsers.count;
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
