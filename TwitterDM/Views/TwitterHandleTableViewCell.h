//
//  TwitterHandleTableViewCell.h
//  TwitterDM
//
//  Created by Vickie Duong on 6/8/15.
//  Copyright (c) 2015 HeartThis. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TwitterHandleTableViewCell : UITableViewCell

@property (nonatomic, weak) NSDictionary *user;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnail;
@property (weak, nonatomic) IBOutlet UILabel *fullNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *handleLabel;

@end
