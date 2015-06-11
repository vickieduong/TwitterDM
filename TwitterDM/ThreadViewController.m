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

// Text view for input
@property (weak, nonatomic) IBOutlet UITextView *textView;

// Tableview to display the messages
@property (strong, nonatomic) IBOutlet UITableView *tableView;

// Bottom constraint of the view to the bottom of its container - adjusts for keyboard show/hide
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

// Array of messages (model)
@property (nonatomic, strong) NSMutableArray *messages;

// Constraint for height of text box (autolayout)
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewHeightConstraint;

// Keyboard height, once calculated
@property (nonatomic) CGFloat keyboardHeight;

// Sizing cells (mine & theirs) to use to calculate row heights
@property (nonatomic, strong) MessageTableViewCell *sizingCellMine;
@property (nonatomic, strong) MessageTableViewCell *sizingCellTheirs;

@end

@implementation ThreadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add tap gesture recognizer to hide the keyboard when the table view (messages) is tapped
    UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditing)];
    [self.tableView addGestureRecognizer:tapper];
    
    // Add bottom and top inset to the messages
    self.tableView.contentInset = UIEdgeInsetsMake(8, 0, 8, 0);
    
    self.messages = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Add self as an observer for keyboard notifications, to calculate the keyboard height
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardShown:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [self setUserTitle];
}

- (void)setUser:(NSDictionary *)user {
    _user = user;
    [self setUserTitle];
}

- (void)setUserTitle {
    if(self.user) {
        // Set the title based on the user screen name
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
    
    // Put focus in the text view input on appear
    [self.textView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Hide the keyboard
    [self.view endEditing:YES];
    
    // Remove self as an observer (of keyboard events, and all others)
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)endEditing {
    [self.view endEditing:YES];
}

#pragma mark - Keyboard height

// Change the view based on keyboard showing or hiding

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

#pragma mark - Scroll to bottom (upon inserting a message)

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

// Configure the UITableViewCell for the message (set the text in the label)
- (void)configureBasicCell:(MessageTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    DirectMessage *msg = self.messages[indexPath.row];
    NSString *text = msg.text;
    [cell setText:text isMine:msg.isMine];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self heightForBasicCellAtIndexPath:indexPath];
}

// Use dynamic heights for the message cells based on their content
- (CGFloat)heightForBasicCellAtIndexPath:(NSIndexPath *)indexPath {
    DirectMessage *msg = self.messages[indexPath.row];
    BOOL isMine = msg.isMine;
    
    // Get an empty UITableViewCell for sizing (will configure it as we would for display, and get it's height to return)
    MessageTableViewCell *sizingCell;
    if(isMine) {
        if(!self.sizingCellMine) {
            self.sizingCellMine = [self.tableView dequeueReusableCellWithIdentifier:@"MessageTableViewCellMine"];
        }
        sizingCell = self.sizingCellMine;
    } else {
        if(!self.sizingCellTheirs) {
            self.sizingCellTheirs = [self.tableView dequeueReusableCellWithIdentifier:@"MessageTableViewCellTheirs"];
        }
        sizingCell = self.sizingCellTheirs;
    }
    
    [self configureBasicCell:sizingCell atIndexPath:indexPath];
    return [sizingCell getEstimatedHeight];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0f;
}

// User pressed send
- (IBAction)sendTouch:(id)sender {
    // disable the send button
    [sender setEnabled:NO];

    NSString *text = self.textView.text;
    
    // Add the users message (mine)
    DirectMessage *msg = [[DirectMessage alloc] init];
    msg.text = text;
    msg.isMine = YES;
    msg.date = [NSDate date];
    
    [self addMessage:msg];
    
    // Insert a reply 1.0 seconds after the user sends this message (theirs)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        DirectMessage *msg = [[DirectMessage alloc] init];
        msg.text = [text stringByAppendingString:[NSString stringWithFormat:@" %@", text]];
        msg.isMine = NO;
        msg.date = [NSDate date];
        
        [self addMessage:msg];
    });
    
    // Reset the UITextView text and height
    self.textView.text = @"";
    self.textViewHeightConstraint.constant = 30;

    // enable the send button
    [sender setEnabled:YES];
}

// Increase height of text view (up to a certain max) as the user types in the UITextView
- (void)textViewDidChange:(UITextView *)textView {
    NSDictionary *attributes = @{NSFontAttributeName: self.textView.font};
    
    NSString *text = self.textView.text;
    
    NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
    NSRange range = [text rangeOfCharacterFromSet:cset];
    if (range.location == NSNotFound) {
        // no newline, this is only one line of text, set min height to 30
        self.textViewHeightConstraint.constant = 30;
    } else {
        // contains newline
        // NSString class method: boundingRectWithSize:options:attributes:context is
        // available only on ios7.0 sdk.
        
        // Get the height of the text
        CGRect rect = [text boundingRectWithSize:CGSizeMake(self.textView.frame.size.width, CGFLOAT_MAX)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:attributes
                                         context:nil];
        
        CGFloat height = rect.size.height;
        
        // Get the height of one extra line
        CGRect oneLineRect = [@"" boundingRectWithSize:CGSizeMake(self.textView.frame.size.width, CGFLOAT_MAX)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:attributes
                                               context:nil];
        
        height += (self.textView.contentInset.top + self.textView.contentInset.bottom + oneLineRect.size.height);
        
        if([text length] > 0) {
            // If the last character is a new line \n, then add one more line height
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

// Add a message to the tableview
- (void)addMessage:(DirectMessage *)msg {
    @synchronized (self.messages) {
        NSInteger prevCount = self.messages.count;
        
        [self.messages addObject:msg];
        
        // Reload the table view (or insert the row) to refresh the UI
        if(prevCount <= 0) {
            [self.tableView reloadData];
        } else {
            NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:1];
            [indexPaths addObject:[NSIndexPath indexPathForRow:prevCount inSection:0]];
            
            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationBottom];
        }
        
        // Keep the message thread scrolled to the newly inserted row upon insertion
        dispatch_async(dispatch_get_main_queue(), ^{
            [self scrollToBottom];
        });
    }
}

@end
