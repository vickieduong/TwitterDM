//
//  ViewController.m
//  TwitterDM
//
//  Created by Vickie Duong on 6/8/15.
//  Copyright (c) 2015 HeartThis. All rights reserved.
//

#import "LoginViewController.h"
@import Accounts;

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditing)];
    [self.view addGestureRecognizer:tapper];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)endEditing {
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    if (textField == self.usernameTextField) {
        [self.passwordTextField becomeFirstResponder];
    }
    return NO;
}

- (IBAction)loginTouch:(id)sender {
    NSString *token = @"";
    NSString *secret = @"";
    
    ACAccountCredential *credential = [[ACAccountCredential alloc] initWithOAuthToken:token tokenSecret:secret];

    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    ACAccount *account = [[ACAccount alloc] initWithAccountType:accountType];
    [account setUsername:self.usernameTextField.text];
    [account setCredential:credential];
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        if (granted == YES) {
            [accountStore saveAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
                if (success) {
                    NSLog(@"the account was saved!");
                }
                else {
                    if ([error code] == ACErrorPermissionDenied) {
                        NSLog(@"Got a ACErrorPermissionDenied, the account was not saved!");
                    }
                    NSLog(@"the account was not saved! %d, %@", [error code], error);
                }
            }];
        } else {
            NSLog(@"ERR: %@ ",error);
        }
    }];
}

@end
