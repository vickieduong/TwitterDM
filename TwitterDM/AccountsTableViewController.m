//
//  AccountsTableViewController.m
//  TwitterDM
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
    
    ACAccount *user = [self.accounts objectAtIndex:indexPath.row];
    cell.handleLabel.text = user.username;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ACAccount *account = [self.accounts objectAtIndex:indexPath.row];
    
    if(self.delegate) {
        [self.delegate setTwitterAccount:account];
    }
    
    [self backTouch];
}

- (void)backTouch {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
