//
//  ContainerView.m
//  IJKPlayerDemo
//
//  Created by 冯晓林 on 2018/6/11.
//  Copyright © 2018年 FXL. All rights reserved.
//

#import "ContainerView.h"

@implementation ContainerView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.image = [UIImage imageNamed:@"container"];
        self.userInteractionEnabled = YES;
//        self.layer.masksToBounds = YES;
    }
    return self;
}

@end
