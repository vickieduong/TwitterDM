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

@property (weak, nonatomic) IBOutlet UIButton *settingsButton;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // ios 8 and above
    if (&UIApplicationOpenSettingsURLString != NULL) {
        self.settingsButton.hidden = NO;
    } else {
        self.settingsButton.hidden = YES;
    }
}

- (IBAction)settingsTouch:(id)sender {
    // only available in > iOS 8
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

@end
