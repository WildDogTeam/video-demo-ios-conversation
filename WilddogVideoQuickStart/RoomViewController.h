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

@property(nonatomic, strong)NSString *appid;
@property(nonatomic, strong)WDGUser *wDGUser;

@end
