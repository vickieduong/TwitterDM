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

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

@end

@implementation ThreadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(self.user) {
        self.navigationItem.title = [NSString stringWithFormat:@"@%@", self.user[@"screen_name"]];
    }
    
    UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditing)];
    [self.tableView addGestureRecognizer:tapper];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardShown:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)endEditing {
    [self.view endEditing:YES];
}

- (void)keyboardHidden:(NSNotification *)notification {
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [self updateBottomConstraint:0 withDuraction:duration];
}

- (void)keyboardShown:(NSNotification *)notification {
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    CGFloat keyboardHeight = keyboardRect.size.height;
    
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [self updateBottomConstraint:keyboardHeight withDuraction:duration];
}

- (void)updateBottomConstraint:(CGFloat)constant withDuraction:(double)duration {
    self.bottomConstraint.constant = constant;
    
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self basicCellAtIndexPath:indexPath];
}

- (MessageTableViewCell *)basicCellAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isMine = indexPath.row % 2 == 0;
    NSString *reuseIdentifier = isMine ? @"MessageTableViewCellMine" : @"MessageTableViewCellTheirs";
    
    MessageTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    [self configureBasicCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureBasicCell:(MessageTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    BOOL isMine = indexPath.row % 2 == 0;
    
    [cell setText:@"Hello there i love to message things on twitter this is amazing ok bye!" isMine:isMine];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self heightForBasicCellAtIndexPath:indexPath];
}

- (CGFloat)heightForBasicCellAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isMine = indexPath.row % 2 == 0;
    
    MessageTableViewCell *sizingCell;
    if(isMine) {
        static MessageTableViewCell *sizingCellMine = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sizingCellMine = [self.tableView dequeueReusableCellWithIdentifier:@"MessageTableViewCellMine"];
        });
        sizingCell = sizingCellMine;
    } else {
        static MessageTableViewCell *sizingCellTheirs = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sizingCellTheirs = [self.tableView dequeueReusableCellWithIdentifier:@"MessageTableViewCellTheirs"];
        });
        sizingCell = sizingCellTheirs;
    }
    
    [self configureBasicCell:sizingCell atIndexPath:indexPath];
    return [sizingCell getEstimatedHeight];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0f;
}


- (IBAction)sendTouch:(id)sender {
}

@end
