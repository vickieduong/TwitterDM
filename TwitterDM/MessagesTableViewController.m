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

typedef enum ScrollDirection {
    ScrollDirectionNone,
    ScrollDirectionRight,
    ScrollDirectionLeft,
    ScrollDirectionUp,
    ScrollDirectionDown,
    ScrollDirectionCrazy,
} ScrollDirection;

// Data from Twitter response for paging through followers
@property (nonatomic, strong) NSDictionary *data;

// Image cache for profile images, keyed by profile image url
@property (nonatomic, strong) NSMutableDictionary *imageCache;

// We fetch 5000 follower ids at a time
@property (nonatomic, strong) NSMutableArray *ids;

// We can only look up 100 users at a time, so we keep ids and users separate.
// Tableview uses users, since we want the data loaded from the user objects
@property (nonatomic, strong) NSMutableArray *users;

// Infinitely loading (followers call)
//@property (nonatomic) BOOL infiniteLoading;

// Infinitely loading (users call)
@property (nonatomic) BOOL loadingUsers;

// End of followers list
@property (nonatomic) BOOL endOfFeed;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *switchAccountsBarButtonItem;

// Multiple twitter accounts
@property (nonatomic, strong) NSArray *accounts;

// Last used twitter name (so we don't recall the endpoint if they don't change the user)
// Also so we know if a Twitter account was deleted, we need to refresh table view with
// new valid Twitter account (if any)
@property (nonatomic, strong) NSString *lastUsername;

// Loading Twitter account information
@property (nonatomic) BOOL loading;

// Spinner
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

// To determine scroll direction (for infinite loading)
@property (nonatomic) CGFloat lastContentOffset;
@property (nonatomic) ScrollDirection scrollDirection;

@end

@implementation MessagesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.users = [[NSMutableArray alloc] init];
    self.ids = [[NSMutableArray alloc] init];
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
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = self.view.center;
    [self.view addSubview:self.spinner];
    
    self.loading = YES;
    [self.spinner startAnimating];
    [self twitterAccountsUpdated];
}

- (void)twitterAccountsUpdated {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error){
            if (granted) {
                self.accounts = [accountStore accountsWithAccountType:accountType];
                // Check if the users has setup at least one Twitter account
                if (self.accounts.count > 0)
                {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        if(self.accounts.count > 1) {
                            self.switchAccountsBarButtonItem.enabled = YES;
                        } else {
                            self.switchAccountsBarButtonItem.enabled = NO;
                        }
                    });
                    
                    if(!self.lastUsername || ![self.twitterAccount.username isEqualToString:self.lastUsername] || ![self.accounts containsObject:self.twitterAccount]) {
                        self.twitterAccount = [self.accounts firstObject];
                    }
                } else {
                    self.twitterAccount = nil;
                }
            } else {
                self.accounts = nil;
                self.twitterAccount = nil;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:@"Oops!" message:@"We need permission to access your Twitter accounts. Please enable in your Settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                });
            }
        }];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    @synchronized(self.imageCache) {
        [self.imageCache removeAllObjects];
    }
}

// When the Twitter account is updated, set the last username to this Twitter account username
- (void)setTwitterAccount:(ACAccount *)twitterAccount {
    dispatch_async(dispatch_get_main_queue(), ^{
        _twitterAccount = twitterAccount;
        
        _lastUsername = twitterAccount.username;
        
        _endOfFeed = NO;
        
        self.loading = YES;
        
        self.data = nil;
        [self.users removeAllObjects];
        [self.ids removeAllObjects];
        
        [self.tableView reloadData];
        
        if(twitterAccount) {
            [self.spinner startAnimating];
            
            SLRequest *twitterInfoRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                               requestMethod:SLRequestMethodGET
                                                                         URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/followers/ids.json?"]
                                                                  parameters:@{
                                                                               @"screen_name" : self.twitterAccount.username,
                                                                               @"cursor": @"-1"
                                                                               }
                                             ];
            [twitterInfoRequest setAccount:self.twitterAccount];
            [twitterInfoRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                [self handleFollowersResponse:responseData urlResponse:urlResponse error:error];
            }];
        } else {
            self.loading = NO;
            [self.spinner stopAnimating];
            [self.tableView reloadData];
        }
    });
}

- (void)loadUsersBatch {
    if(!self.loadingUsers) {
        self.loadingUsers = YES;
        
        // NSLog(@"loading next user batch users:%lu ids:%lu", (unsigned long)self.users.count, (unsigned long)self.ids.count);
        
        NSArray *idSet;
        @synchronized(self.ids) {
            NSRange range = NSMakeRange(0, MIN(self.ids.count, 100));
            idSet = [self.ids subarrayWithRange:range];
            [self.ids removeObjectsInRange:range];
        }
        SLRequest *twitterInfoRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                           requestMethod:SLRequestMethodGET
                                                                     URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/users/lookup.json?"]
                                                              parameters:@{
                                                                           @"user_id": [idSet componentsJoinedByString:@","]
                                                                           }
                                         ];
        [twitterInfoRequest setAccount:self.twitterAccount];
        [twitterInfoRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            [self handleTwitterUserResponse:responseData urlResponse:urlResponse error:error];
        }];
    }
}

- (void)handleTwitterUserResponse:(NSData*)responseData urlResponse:(NSHTTPURLResponse *)urlResponse error:(NSError *)error {
    // Check if we reached the rate limit
    if ([urlResponse statusCode] == 429) {
        NSLog(@"Rate limit reached");
        self.loading = NO;
        self.loadingUsers = NO;
        [self.spinner stopAnimating];
        return;
    }
    // Check if there was an error
    if (error) {
        NSLog(@"Error: %@", error.localizedDescription);
        self.loading = NO;
        self.loadingUsers = NO;
        [self.spinner stopAnimating];
        return;
    }
    // Check if there is some response data
    if (responseData) {
        NSError *error = nil;
        NSArray *TWData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];
        
        if([TWData isKindOfClass:[NSArray class]]) {
            @synchronized(self.users) {
                [self.users addObjectsFromArray:TWData];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loading = NO;
            self.loadingUsers = NO;
            [self.spinner stopAnimating];
            
            [self.tableView reloadData];
        });
    }
}

- (void)handleFollowersResponse:(NSData*)responseData urlResponse:(NSHTTPURLResponse *)urlResponse error:(NSError *)error {
    // Check if we reached the rate limit
    if ([urlResponse statusCode] == 429) {
        NSLog(@"Rate limit reached");
        self.loading = NO;
        [self.spinner stopAnimating];
        return;
    }
    // Check if there was an error
    if (error) {
        NSLog(@"Error: %@", error.localizedDescription);
        self.loading = NO;
        [self.spinner stopAnimating];
        return;
    }
    // Check if there is some response data
    if (responseData) {
        NSError *error = nil;
        NSDictionary *TWData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];
        
        self.data = TWData;
        
        // for followers/list endpoint (not using, only fetches 20 at a time, rate limit reached)
        //            if([self.data objectForKey:@"users"] && [[self.data objectForKey:@"users"] isKindOfClass:[NSArray class]]) {
        //                [self.users addObjectsFromArray:self.data[@"users"]];
        //            }
        
        // for followers/ids endpoint (fetches 5000 at a time, use with users/lookup - 100 at a time)
        if([self.data objectForKey:@"ids"] && [[self.data objectForKey:@"ids"] isKindOfClass:[NSArray class]]) {
            @synchronized(self.ids) {
                [self.ids addObjectsFromArray:self.data[@"ids"]];
            }
            [self loadUsersBatch];
        }
        
        if([self.data[@"next_cursor_str"] isEqualToString:@"0"]) {
            self.endOfFeed = YES;
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.loading) {
        return 0;
    }
    return MAX(1, self.users.count); // minimum of 1 row, for the empty table view cell
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if([cell isKindOfClass:[TwitterHandleTableViewCell class]]) {
        ((TwitterHandleTableViewCell *)cell).thumbnail.image = nil;
    }
}

// Make the separators extend the full width of the screen
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
        // No accounts - show empty instructions that take up the entire table view height
        CGFloat statusBarHeight = ([UIApplication sharedApplication].statusBarFrame.size.height);
        CGFloat navigationBarHeight = (self.navigationController.navigationBar.bounds.size.height);
        CGFloat topBarHeight = statusBarHeight + navigationBarHeight;
        
        CGFloat height = self.tableView.frame.size.height - topBarHeight;
        return height;
    } else {
        // Height for TwitterHandleTableViewCell
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
        
        // Get a copy of this user's username to compare against when the image is done downloading
        NSString *usernameCopy = [username copy];
        
        NSString *urlString = user[@"profile_image_url_https"];
        NSObject *existingImage;
        @synchronized(self.imageCache) {
            existingImage = [self.imageCache objectForKey:urlString];
        }
        
        if(existingImage) {
            [self fadeInImage:(UIImage *)existingImage inImageView:cell.thumbnail];
        } else {
            NSURL *url = [NSURL URLWithString:urlString];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                if(!connectionError && data) {
                    UIImage *image = [UIImage imageWithData:data];
                    if(image) {
                        @synchronized(self.imageCache) {
                            [self.imageCache setObject:image forKey:urlString];
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            // Check if cell's user is the same (since we're reusing table cells)
                            if([cell.user[@"screen_name"] isEqualToString:usernameCopy]) {
                                [self fadeInImage:image inImageView:cell.thumbnail];
                            }
                        });
                    }
                } else {
                    cell.thumbnail.backgroundColor = [UIColor lightGrayColor];
                }
            }];
        }
        
        // Check if we are 50(ish) rows from the bottom, if yes, fetch the next batch of 100 users from the user ids
        if(self.scrollDirection == ScrollDirectionDown && indexPath.row >= self.users.count - 100) {
            [self loadUsersBatch];
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
        // If we are transitioning to a ThreadViewController, set the user on that thread
        TwitterHandleTableViewCell *cell = (TwitterHandleTableViewCell *)sender;
        NSDictionary *user = cell.user;
        
        ThreadViewController *vc = (ThreadViewController *)[segue destinationViewController];
        vc.user = user;
    } else if([sender isKindOfClass:[UIBarButtonItem class]]) {
        // If we are transitioning to the select account table view controller, set the accounts
        UINavigationController *navController = [segue destinationViewController];
        AccountsTableViewController *vc = (AccountsTableViewController *) [[navController viewControllers] objectAtIndex:0];
        vc.delegate = self;
        vc.accounts = self.accounts;
    }
}

#pragma mark - Infinite loading

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    ScrollDirection scrollDirection;
    if (self.lastContentOffset > scrollView.contentOffset.y)
        scrollDirection = ScrollDirectionUp;
    else if (self.lastContentOffset < scrollView.contentOffset.y)
        scrollDirection = ScrollDirectionDown;
    
    self.lastContentOffset = scrollView.contentOffset.y;
    
    self.scrollDirection = scrollDirection;
    
    if(scrollDirection == ScrollDirectionDown && !self.endOfFeed && !self.loading && self.tableView.contentSize.height > self.tableView.frame.size.height && scrollView.contentOffset.y > self.tableView.contentSize.height - (self.tableView.frame.size.height * 2)) {
        [self callInfiniteLoadRequest];
    }
}

- (void)callInfiniteLoadRequest {
    self.loading = YES;
    
    // NSLog(@"loading next set of user ids:%lu ids:%lu", (unsigned long)self.users.count, (unsigned long)self.ids.count);
    
    SLRequest *twitterInfoRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                       requestMethod:SLRequestMethodGET
                                                                 URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/followers/ids.json?"]
                                                          parameters:@{
                                                                       @"screen_name" : self.twitterAccount.username,
                                                                       @"cursor": ([self.data valueForKey:@"next_cursor_str"] ? self.data[@"next_cursor_str"] : @"-1")
                                                                       }
                                     ];
    [twitterInfoRequest setAccount:self.twitterAccount];
    [twitterInfoRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        [self handleFollowersResponse:responseData urlResponse:urlResponse error:error];
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
