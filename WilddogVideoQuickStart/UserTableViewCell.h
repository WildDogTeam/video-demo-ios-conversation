//
//  UserTableViewCell.h
//  WilddogVideoQuickStart
//
//  Created by IMacLi on 16/9/13.
//  Copyright © 2016年 liwuyang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^ClickInviteUser)(NSString *title);

@interface UserTableViewCell : UITableViewCell

@property(nonatomic, strong)ClickInviteUser clickInviteUserBlock;
@property (weak, nonatomic) IBOutlet UILabel *titleLab;

@end
