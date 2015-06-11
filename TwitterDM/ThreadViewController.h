//
//  ThreadViewController.h
//  TwitterDM
//
//  Created by Vickie Duong on 6/8/15.
//  Copyright (c) 2015 HeartThis. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ThreadViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (nonatomic, weak) NSDictionary *user;

@end
