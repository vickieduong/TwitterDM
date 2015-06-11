//
//  AccountsTableViewController.m
//  TwitterDM
//
//  View Controller to view and switch the multiple Twitter accounts logged in on iOS
//
//  Created by Vickie Duong on 6/9/15.
//  Copyright (c) 2015 HeartThis. All rights reserved.
//

#import "AccountsTableViewController.h"
#import "TwitterHandleTableViewCell.h"
#import "MessagesTableViewController.h"

@interface AccountsTableViewController ()

@end

@implementation AccountsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(backTouch)];
    self.navigationItem.leftBarButtonItem = cancel;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.accounts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TwitterHandleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TwitterHandleTableViewCell" forIndexPath:indexPath];

    // Show the account's handle
    ACAccount *user = [self.accounts objectAtIndex:indexPath.row];
    cell.handleLabel.text = user.username;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ACAccount *account = [self.accounts objectAtIndex:indexPath.row];
    
    // When selected an account (row in UITableView), set the account on the delegate
    if(self.delegate && [self.delegate respondsToSelector:@selector(setTwitterAccount:)]) {
        [self.delegate setTwitterAccount:account];
    }
    
    // Close this view
    [self backTouch];
}

- (void)backTouch {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
