//
//  MessagesTableViewController.m
//  TwitterDM
//
//  Created by Vickie Duong on 6/8/15.
//  Copyright (c) 2015 HeartThis. All rights reserved.
//

#import "MessagesTableViewController.h"
#import "TwitterHandleTableViewCell.h"
#import "ThreadViewController.h"
#import "AccountsTableViewController.h"
#import "EmptyTableViewCell.h"

@import Social;

@interface MessagesTableViewController ()

@property (nonatomic, strong) NSMutableDictionary *data;
@property (nonatomic, strong) NSMutableDictionary *imageCache;
@property (nonatomic, strong) NSMutableArray *users;
@property (nonatomic) BOOL infiniteLoading;
@property (nonatomic) BOOL endOfFeed;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *switchAccountsBarButtonItem;
@property (nonatomic, strong) NSArray *accounts;
@property (nonatomic, strong) NSString *lastUsername;

@property (nonatomic) BOOL loading;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end

@implementation MessagesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.data = [[NSMutableDictionary alloc] init];
    self.users = [[NSMutableArray alloc] init];
    self.imageCache = [[NSMutableDictionary alloc] init];
    
    [self.tableView setContentInset:UIEdgeInsetsZero];
    
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(twitterAccountsUpdated) name:@"ApplicationEnteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(twitterAccountsUpdated) name:@"ACAccountStoreDidChangeNotification" object:nil];
    
    self.tableView.alwaysBounceVertical = NO;
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    self.spinner.center = self.tableView.center;
    [self.tableView addSubview:self.spinner];
    
    self.loading = YES;
    [self.spinner startAnimating];
    [self twitterAccountsUpdated];
}

- (void)twitterAccountsUpdated {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error){
        if (granted) {
            self.accounts = [accountStore accountsWithAccountType:accountType];
            // Check if the users has setup at least one Twitter account
            if (self.accounts.count > 0)
            {
                [self dismissViewControllerAnimated:NO completion:nil];
                
                if(self.accounts.count > 1) {
                    self.switchAccountsBarButtonItem.enabled = YES;
                } else {
                    self.switchAccountsBarButtonItem.enabled = NO;
                }
                
                if(!self.lastUsername || ![self.twitterAccount.username isEqualToString:self.lastUsername] || ![self.accounts containsObject:self.twitterAccount]) {
                    self.twitterAccount = [self.accounts firstObject];
                }
            } else {
                self.twitterAccount = nil;
                //                [self presentLogin];
            }
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Oops!" message:@"We need permission to access your Twitter accounts. Please enable in your Settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.imageCache removeAllObjects];
}

- (void)setTwitterAccount:(ACAccount *)twitterAccount {
    _twitterAccount = twitterAccount;
    
    _lastUsername = twitterAccount.username;
    
    _endOfFeed = NO;
    
    [self.data removeAllObjects];
    [self.users removeAllObjects];
    
    [self.tableView reloadData];
    
    if(twitterAccount) {
        self.loading = YES;
        [self.spinner startAnimating];
        
        SLRequest *twitterInfoRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/followers/list.json?"] parameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@", self.twitterAccount.username], @"screen_name", @"-1", @"cursor", nil]];
        [twitterInfoRequest setAccount:self.twitterAccount];
        [twitterInfoRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            [self handleTwitterResponse:responseData urlResponse:urlResponse error:error];
        }];
    } else {
        self.loading = NO;
        [self.spinner stopAnimating];
        [self.tableView reloadData];
    }
}

- (void)handleTwitterResponse:(NSData*)responseData urlResponse:(NSHTTPURLResponse *)urlResponse error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.loading = NO;
        [self.spinner stopAnimating];
        
        // Check if we reached the rate limit
        if ([urlResponse statusCode] == 429) {
            NSLog(@"Rate limit reached");
            return;
        }
        // Check if there was an error
        if (error) {
            NSLog(@"Error: %@", error.localizedDescription);
            return;
        }
        // Check if there is some response data
        if (responseData) {
            NSError *error = nil;
            NSDictionary *TWData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];
            
            [self.data addEntriesFromDictionary:TWData];
            
            if([self.data objectForKey:@"users"] && [[self.data objectForKey:@"users"] isKindOfClass:[NSArray class]]) {
                [self.users addObjectsFromArray:self.data[@"users"]];
            }
            [self.tableView reloadData];
            
            if([self.data[@"next_cursor_str"] isEqualToString:@"0"]) {
                self.endOfFeed = YES;
            }
        }
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.loading) {
        return 0;
    }
    return MAX(1, self.users.count);
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if([cell isKindOfClass:[TwitterHandleTableViewCell class]]) {
        ((TwitterHandleTableViewCell *)cell).thumbnail.image = nil;
    }
}

// for ios 7 vs ios 8
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIEdgeInsets insets = UIEdgeInsetsZero;
    
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:insets];
    }
    
    if(indexPath.row < [tableView numberOfRowsInSection:indexPath.section] - 1) {
        if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
            [cell setLayoutMargins:insets];
        }
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.accounts.count <= 0) {
        CGFloat statusBarHeight = ([UIApplication sharedApplication].statusBarFrame.size.height);
        CGFloat navigationBarHeight = (self.navigationController.navigationBar.bounds.size.height);
        CGFloat topBarHeight = statusBarHeight + navigationBarHeight;

        CGFloat height = self.tableView.frame.size.height - topBarHeight;
        NSLog(@"%f", height);
        return height;
    } else {
        return 75.0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.accounts.count <= 0) {
        EmptyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EmptyTableViewCell" forIndexPath:indexPath];
        return cell;
    } else {
        TwitterHandleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TwitterHandleTableViewCell" forIndexPath:indexPath];
        
        NSDictionary *user = [self.users objectAtIndex:indexPath.row];
        
        cell.user = user;
        
        NSString *username = user[@"screen_name"];
        cell.fullNameLabel.text = user[@"name"];
        cell.handleLabel.text = username;
        
        NSString *urlString = user[@"profile_image_url_https"];
        if([self.imageCache objectForKey:urlString]) {
            UIImage *image = [self.imageCache objectForKey:urlString];
            [self fadeInImage:image inImageView:cell.thumbnail];
        } else {
            NSURL *url = [NSURL URLWithString:urlString];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                if(!connectionError && data) {
                    UIImage *image = [UIImage imageWithData:data];
                    [self.imageCache setObject:image forKey:urlString];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self fadeInImage:image inImageView:cell.thumbnail];
                    });
                } else {
                    cell.thumbnail.backgroundColor = [UIColor lightGrayColor];
                }
            }];
        }
        
        return cell;
    }
}

- (void)fadeInImage:(UIImage *)image inImageView:(UIImageView *)imageView {
    [UIView transitionWithView:imageView
                      duration:0.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        [imageView setImage:image];
                    } completion:nil];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([sender isKindOfClass:[TwitterHandleTableViewCell class]]) {
        TwitterHandleTableViewCell *cell = (TwitterHandleTableViewCell *)sender;
        NSDictionary *user = cell.user;
        
        ThreadViewController *vc = (ThreadViewController *)[segue destinationViewController];
        vc.user = user;
    } else if([sender isKindOfClass:[UIBarButtonItem class]]) {
        UINavigationController *navController = [segue destinationViewController];
        AccountsTableViewController *vc = (AccountsTableViewController *) [[navController viewControllers] objectAtIndex:0];
        vc.delegate = self;
        vc.accounts = self.accounts;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(!self.endOfFeed && !self.infiniteLoading && self.tableView.contentSize.height > self.tableView.frame.size.height && scrollView.contentOffset.y > self.tableView.contentSize.height - (self.tableView.frame.size.height * 2)) {
        [self callInfiniteLoadRequest];
    }
}

- (void)callInfiniteLoadRequest {
    self.infiniteLoading = YES;
    
    SLRequest *twitterInfoRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                       requestMethod:SLRequestMethodGET
                                                                 URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/followers/list.json?"]
                                                          parameters:@{
                                                                       @"screen_name" : self.twitterAccount.username,
                                                                       @"cursor": self.data[@"next_cursor_str"]
                                                                       }
                                     ];
    [twitterInfoRequest setAccount:self.twitterAccount];
    [twitterInfoRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        [self handleTwitterResponse:responseData urlResponse:urlResponse error:error];
        self.infiniteLoading = NO;
    }];
}

- (void)reloadTableView
{
    [UIView setAnimationsEnabled:NO];
    
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
    
    [UIView setAnimationsEnabled:YES];
}

@end
