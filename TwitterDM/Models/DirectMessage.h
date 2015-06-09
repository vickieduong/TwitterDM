//
//  DirectMessage.h
//  TwitterDM
//
//  Created by Vickie Duong on 6/9/15.
//  Copyright (c) 2015 HeartThis. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DirectMessage : NSObject

@property (nonatomic) BOOL isMine;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSDate *date;

@end
