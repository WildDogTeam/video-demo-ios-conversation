//
//  UserTableViewCell.m
//  WilddogVideoQuickStart
//
//  Created by IMacLi on 16/9/13.
//  Copyright © 2016年 liwuyang. All rights reserved.
//

#import "UserTableViewCell.h"

@implementation UserTableViewCell

- (IBAction)clickInviteBtn:(id)sender {
    if (self.clickInviteUserBlock) {
         self.clickInviteUserBlock(self.titleLabel.text);
    }
}

@end
