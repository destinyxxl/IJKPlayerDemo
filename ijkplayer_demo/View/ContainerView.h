//
//  ContainerView.h
//  IJKPlayerDemo
//
//  Created by 冯晓林 on 2018/6/11.
//  Copyright © 2018年 FXL. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ViewState) {
    ViewStateSmall,
    ViewStateAnimating,
    ViewStateFullScreen,
};

@interface ContainerView : UIImageView

/**
 记录小屏时的parentView
 */
@property (nonatomic, weak) UIView *movieViewParentView;
/**
 记录小屏时的frame
 */
@property (nonatomic, assign) CGRect movieViewFrame;

@property (nonatomic, assign) ViewState state;

@end
