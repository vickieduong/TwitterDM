//
//  MessagesTableViewController.h
//  TwitterDM
//
//  Created by Vickie Duong on 6/8/15.
//  Copyright (c) 2015 HeartThis. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Accounts;
#import "AccountsTableViewController.h"

@interface MessagesTableViewController : UITableViewController <AccountsTableViewControllerDelegate>

@property (nonatomic, strong) ACAccount *twitterAccount;

@end
