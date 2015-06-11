//
//  ThreadViewController.h
//  TwitterDM
//
//  View Controller for viewing one direct message thread with a Twitter user
//  For now, when the user posts a message, there is an automatic reply
//  after a 1 second delay with the same text, but repeated (in the same message)
//
//  Created by Vickie Duong on 6/8/15.
//  Copyright (c) 2015 HeartThis. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ThreadViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (nonatomic, weak) NSDictionary *user;

@end
