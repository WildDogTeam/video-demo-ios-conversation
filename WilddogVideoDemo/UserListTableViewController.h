//
//  UserListTableTableViewController.h
//  WilddogVideoDemo
//
//  Created by Hayden on 2017/9/16.
//  Copyright © 2017年 Wilddog. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WilddogSync/WilddogSync.h>

typedef void (^WDGSelectedUser)(NSString *user);

@interface UserListTableViewController : UITableViewController

@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong) WDGSyncReference *usersReference;
@property (nonatomic, strong) WDGSelectedUser selectedUserBlock;

@end
