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
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewHeightConstraint;

@property (nonatomic) CGFloat keyboardHeight;

@end

@implementation ThreadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    
    if(self.user) {
        self.navigationItem.title = [NSString stringWithFormat:@"@%@", self.user[@"screen_name"]];
        
        CGFloat navbarHeight = self.navigationController.navigationBar.frame.size.height;
        CGFloat headerWidth = ScreenWidth / 2;
        
        UIView *customHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, headerWidth, navbarHeight)];
        customHeader.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 4, headerWidth, navbarHeight / 2)];
        nameLabel.font = [UIFont boldSystemFontOfSize:16.0];
        nameLabel.text = self.user[@"name"];
        nameLabel.textAlignment = NSTextAlignmentCenter;
        nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        UILabel *handleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, navbarHeight / 2, headerWidth, navbarHeight / 2)];
        handleLabel.text = [NSString stringWithFormat:@"@%@", self.user[@"screen_name"]];
        handleLabel.font = [UIFont fontWithName:handleLabel.font.fontName size:12.0];
        handleLabel.textColor = [UIColor lightGrayColor];
        handleLabel.textAlignment = NSTextAlignmentCenter;
        handleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        [customHeader addSubview:nameLabel];
        [customHeader addSubview:handleLabel];
        
        self.navigationItem.titleView = customHeader;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.textView becomeFirstResponder];
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
    self.keyboardHeight = keyboardHeight;
    
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
        self.textViewHeightConstraint.constant = 30;
    }
    [sender setEnabled:YES];
}

- (void)textViewDidChange:(UITextView *)textView {
    NSDictionary *attributes = @{NSFontAttributeName: self.textView.font};
    
    NSString *text = self.textView.text;
    
    NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
    NSRange range = [text rangeOfCharacterFromSet:cset];
    if (range.location == NSNotFound) {
        // no newline
        self.textViewHeightConstraint.constant = 30;
    } else {
        // contains newline
        // NSString class method: boundingRectWithSize:options:attributes:context is
        // available only on ios7.0 sdk.
        CGRect rect = [text boundingRectWithSize:CGSizeMake(self.textView.frame.size.width, CGFLOAT_MAX)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:attributes
                                         context:nil];
        
        CGFloat height = rect.size.height;
        
        CGRect oneLineRect = [@"" boundingRectWithSize:CGSizeMake(self.textView.frame.size.width, CGFLOAT_MAX)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:attributes
                                               context:nil];
        
        height += (self.textView.contentInset.top + self.textView.contentInset.bottom + oneLineRect.size.height);
        
        if([text length] > 0) {
            unichar last = [text characterAtIndex:[text length] - 1];
            if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:last]) {
                // ends with newline
                height += oneLineRect.size.height;
            }
        }
        
        CGFloat textViewMaxHeight = self.view.frame.size.height - self.keyboardHeight - 200.0f;
        
        CGFloat newHeight = MIN(height, textViewMaxHeight);
        self.textViewHeightConstraint.constant = newHeight;
    }
}

- (void)addMessage:(DirectMessage *)msg {
    @synchronized (self.messages) {
        NSInteger prevCount = self.messages.count;
        
        [self.messages addObject:msg];
        
        if(prevCount <= 0) {
            [self.tableView reloadData];
        } else {
            NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:1];
            [indexPaths addObject:[NSIndexPath indexPathForRow:prevCount inSection:0]];
            
            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationBottom];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self scrollToBottom];
        });
    }
}

@end
