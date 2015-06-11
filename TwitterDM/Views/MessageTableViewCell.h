//
//  MessageTableViewCell.h
//  TwitterDM
//
//  Created by Vickie Duong on 6/8/15.
//  Copyright (c) 2015 HeartThis. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessageTableViewCell : UITableViewCell

- (void)setText:(NSString *)text isMine:(BOOL)isMine;
- (CGFloat)getEstimatedHeight;

@end
