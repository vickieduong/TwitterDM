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

@property (nonatomic, retain) UIView *customView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (nonatomic, strong) UIImageView *bubbleImage;
@property (nonatomic) BOOL isMine;

@end

@implementation MessageTableViewCell

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self redrawBubble];
}

- (void)setText:(NSString *)text isMine:(BOOL)isMine {
    self.isMine = isMine;
    self.label.text = text;
    [self.label sizeToFit];
    [self redrawBubble];
}

- (void)redrawBubble {
    // Redraw the bubble so that it matches the size of the text label (+ insets)
    
    if (!self.bubbleImage) {
        self.bubbleImage = [[UIImageView alloc] init];
        [self addSubview:self.bubbleImage];
    }
    
    UIEdgeInsets insets = UIEdgeInsetsMake(10, 16, 10, 16);
    
    // Get the size of the label that fits in the given width (-50 so that it doesn't span the entire screen width)
    CGSize size = [self.label sizeThatFits:CGSizeMake(ScreenWidth - 50 - insets.left, CGFLOAT_MAX)];
    
    CGFloat width = size.width;
    CGFloat height = size.height;
    
    // Calculate the x coordinate of the bubble
    CGFloat x = (self.isMine) ? self.frame.size.width - width - insets.left - insets.right : 0;
    CGFloat y = 0;
    
    // Set the image based on mine or theirs
    if (self.isMine) {
        self.bubbleImage.image = [[UIImage imageNamed:@"right_bubble.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:14];
    } else {
        self.bubbleImage.image = [[UIImage imageNamed:@"left_bubble.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:14];
    }
    
    self.bubbleImage.frame = CGRectMake(x, y, width + insets.left + insets.right, height + insets.top + insets.bottom);
}

// Returns the height of the bubble image for the containing UITableView AFTER redrawBubble has been called
- (CGFloat)getEstimatedHeight {
    return self.bubbleImage.frame.size.height;
}

@end
