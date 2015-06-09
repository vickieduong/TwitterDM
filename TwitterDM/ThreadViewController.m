//
//  ThreadViewController.m
//  TwitterDM
//
//  Created by Vickie Duong on 6/8/15.
//  Copyright (c) 2015 HeartThis. All rights reserved.
//

#import "ThreadViewController.h"
#import "MessageTableViewCell.h"
#import "DirectMessage.h"

@interface ThreadViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (nonatomic, strong) NSMutableArray *messages;

@end

@implementation ThreadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(self.user) {
        self.navigationItem.title = [NSString stringWithFormat:@"@%@", self.user[@"screen_name"]];
    }
    
    UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditing)];
    [self.tableView addGestureRecognizer:tapper];
    
    self.tableView.contentInset = UIEdgeInsetsMake(8, 0, 8, 0);
    
    self.messages = [[NSMutableArray alloc] init];
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
    
    [self updateBottomConstraint:0 withDuration:duration];
}

- (void)keyboardShown:(NSNotification *)notification {
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    CGFloat keyboardHeight = keyboardRect.size.height;
    
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [self updateBottomConstraint:keyboardHeight withDuration:duration];
}

- (void)updateBottomConstraint:(CGFloat)constant withDuration:(double)duration {
    self.bottomConstraint.constant = constant;
    
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self scrollToBottom];
    }];
}

- (void)scrollToBottom {
    NSInteger index = self.messages.count - 1;
    if(index >= 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self basicCellAtIndexPath:indexPath];
}

- (MessageTableViewCell *)basicCellAtIndexPath:(NSIndexPath *)indexPath {
    DirectMessage *msg = self.messages[indexPath.row];
    BOOL isMine = msg.isMine;
    
    NSString *reuseIdentifier = isMine ? @"MessageTableViewCellMine" : @"MessageTableViewCellTheirs";
    
    MessageTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    [self configureBasicCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureBasicCell:(MessageTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    DirectMessage *msg = self.messages[indexPath.row];
    NSString *text = msg.text;
    [cell setText:text isMine:msg.isMine];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self heightForBasicCellAtIndexPath:indexPath];
}

- (CGFloat)heightForBasicCellAtIndexPath:(NSIndexPath *)indexPath {
    DirectMessage *msg = self.messages[indexPath.row];
    BOOL isMine = msg.isMine;
    
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
    [sender setEnabled:NO];
    NSString *text = self.textView.text;
    NSString *trimmed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if(![trimmed isEqualToString:@""]) {
        DirectMessage *msg = [[DirectMessage alloc] init];
        msg.text = trimmed;
        msg.isMine = YES;
        msg.date = [NSDate date];
        
        [self addMessage:msg];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            DirectMessage *msg = [[DirectMessage alloc] init];
            msg.text = [trimmed stringByAppendingString:[NSString stringWithFormat:@" %@", trimmed]];
            msg.isMine = NO;
            msg.date = [NSDate date];
            
            [self addMessage:msg];
        });
        
        self.textView.text = @"";
    }
    [sender setEnabled:YES];
}

- (void)addMessage:(DirectMessage *)msg {
    @synchronized (self.messages) {
        [self.messages addObject:msg];
        
//        NSInteger row = self.messages.count;
//        if(row <= 0) {
            [self.tableView reloadData];
//        } else {
//            NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:1];
//            [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
//            
//            [self.tableView beginUpdates];
//            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationBottom];
//            [self.tableView endUpdates];
//        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self scrollToBottom];
        });
    }
}

@end
