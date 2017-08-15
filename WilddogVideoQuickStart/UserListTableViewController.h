//
//  UserListTableViewController.h
//  WilddogVideoQuickStart
//
//  Created by IMacLi on 16/9/13.
//  Copyright © 2016年 liwuyang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WilddogSync/WilddogSync.h>

typedef void (^WDGSelectedUser)(NSString *user);

@interface UserListTableViewController : UITableViewController

@property (nonatomic, assign) NSString *userID;
@property (nonatomic, strong) WDGSyncReference *usersReference;
@property (nonatomic, strong) WDGSelectedUser selectedUserBlock;

@end
