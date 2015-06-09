//
//  MessageUILabel.m
//  TwitterDM
//
//  Created by Vickie Duong on 6/9/15.
//  Copyright (c) 2015 HeartThis. All rights reserved.
//

#import "MessageUILabel.h"

@implementation MessageUILabel

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    
    // If this is a multiline label, need to make sure
    // preferredMaxLayoutWidth always matches the frame width
    // (i.e. orientation change can mess this up)
    
    if (self.numberOfLines == 0 && bounds.size.width != self.preferredMaxLayoutWidth) {
        self.preferredMaxLayoutWidth = self.bounds.size.width;
        [self setNeedsUpdateConstraints];
    }
}

@end
