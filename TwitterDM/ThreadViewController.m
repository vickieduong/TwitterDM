//
//  ThreadViewController.m
//  TwitterDM
//
//  Created by Vickie Duong on 6/8/15.
//  Copyright (c) 2015 HeartThis. All rights reserved.
//

#import "ThreadViewController.h"
#import "MessageTableViewCell.h"

@interface ThreadViewController ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ThreadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(self.user) {
        self.navigationItem.title = [NSString stringWithFormat:@"@%@", self.user[@"screen_name"]];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isMine = indexPath.row % 2 == 0;
    NSString *reuseIdentifier = isMine ? @"MessageTableViewCellMine" : @"MessageTableViewCellTheirs";
    MessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    [cell setText:@"Hello there i love to message things on twitter this is amazing ok bye!" isMine:isMine];
    
    return cell;
}

@end
