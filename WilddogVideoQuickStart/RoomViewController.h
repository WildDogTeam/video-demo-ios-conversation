//
//  RoomViewController.h
//  WilddogVideoQuickStart
//
//  Created by IMacLi on 16/9/12.
//  Copyright © 2016年 liwuyang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WilddogAuth/WilddogAuth.h>

@interface RoomViewController : UIViewController

@property (nonatomic, strong) WDGUser *user;
@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *appId;

@end
