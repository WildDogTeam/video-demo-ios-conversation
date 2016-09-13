//
//  UserListTableViewController.h
//  WilddogVideoQuickStart
//
//  Created by IMacLi on 16/9/13.
//  Copyright © 2016年 liwuyang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WilddogSync/WilddogSync.h>
typedef void (^selectedUser)(NSString *user);

@interface UserListTableViewController : UITableViewController
@property(nonatomic, assign) NSString *userID;
@property(nonatomic, strong) WDGSyncReference *wilddog;
@property(nonatomic, strong) selectedUser selectedUserBlock;

@end
