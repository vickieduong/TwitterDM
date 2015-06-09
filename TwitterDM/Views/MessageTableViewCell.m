//
//  MessageTableViewCell.m
//  TwitterDM
//
//  Created by Vickie Duong on 6/8/15.
//  Copyright (c) 2015 HeartThis. All rights reserved.
//

#import "MessageTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

@interface MessageTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (nonatomic, strong) UIView *customView;
@property (nonatomic, strong) UIImageView *bubbleImage;
@property (nonatomic) BOOL isMine;

@end

@implementation MessageTableViewCell

@synthesize customView = _customView;
@synthesize bubbleImage = _bubbleImage;

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self redrawBubble];
}

- (void)setText:(NSString *)text isMine:(BOOL)isMine
{
    self.label.text = text;
    [self.label sizeToFit];
    [self redrawBubble];
}

- (void) redrawBubble
{
    if (!self.bubbleImage) {
        self.bubbleImage = [[UIImageView alloc] init];
        [self addSubview:self.bubbleImage];
    }
    
    CGFloat width = self.label.frame.size.width;
    CGFloat height = self.label.frame.size.height;
    
    UIEdgeInsets insets = UIEdgeInsetsMake(8, 8, 8, 8);
    
    CGFloat x = (!self.isMine) ? 0 : self.frame.size.width - width - insets.left - insets.right;
    CGFloat y = 0;
    
    [self.customView removeFromSuperview];
    self.customView = self.label;
    self.customView.frame = CGRectMake(x + insets.left, y + insets.top, width, height);
    [self.contentView addSubview:self.customView];
    
    if (!self.isMine) {
        self.bubbleImage.image = [[UIImage imageNamed:@"left_bubble.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:14];
    } else {
        self.bubbleImage.image = [[UIImage imageNamed:@"right_bubble.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:14];
    }
    
    self.bubbleImage.frame = CGRectMake(x, y, width + insets.left + insets.right, height + insets.top + insets.bottom);
}

@end
