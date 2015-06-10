//
//  AccountsTableViewController.h
//  TwitterDM
//
//  Created by Vickie Duong on 6/9/15.
//  Copyright (c) 2015 HeartThis. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Accounts;

@protocol AccountsTableViewControllerDelegate <NSObject>

- (void)setTwitterAccount:(ACAccount *)account;

@end

@interface AccountsTableViewController : UITableViewController

@property (nonatomic, strong) NSArray *accounts;
@property (nonatomic, weak) id<AccountsTableViewControllerDelegate> delegate;

@end
