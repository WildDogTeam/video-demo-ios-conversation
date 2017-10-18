//
//  ConversationViewController.h
//  WilddogVideoDemo
//
//  Created by Hayden on 2017/9/16.
//  Copyright © 2017年 Wilddog. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WilddogAuth/WilddogAuth.h>
#import <WilddogVideoBase/WDGLocalStreamOptions.h>


@interface ConversationViewController : UIViewController

@property (nonatomic, strong) WDGUser *user;
@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *appId;

@property (nonatomic, assign) BOOL busyFlag;
@property (nonatomic, assign) WDGVideoDimensions resolutionRatio;

@end

