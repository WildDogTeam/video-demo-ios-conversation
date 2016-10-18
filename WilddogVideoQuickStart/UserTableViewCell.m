//
//  UserTableViewCell.m
//  WilddogVideoQuickStart
//
//  Created by IMacLi on 16/9/13.
//  Copyright © 2016年 liwuyang. All rights reserved.
//

#import "UserTableViewCell.h"

@implementation UserTableViewCell

- (IBAction)inviteButtonTapped:(id)sender
{
    if (self.inviteUserBlock) {
         self.inviteUserBlock(self.titleLabel.text);
    }
}

@end
