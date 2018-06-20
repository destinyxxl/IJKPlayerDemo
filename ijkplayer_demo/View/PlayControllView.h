//
//  PlayControllView.h
//  IJKPlayerDemo
//
//  Created by 冯晓林 on 2018/6/8.
//  Copyright © 2018年 FXL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerControlViewDelagate.h"
#import <IJKMediaFramework/IJKMediaPlayback.h>

//@protocol IJKMediaPlayback;

@interface PlayControllView : UIView

@property(nonatomic, weak) id<IJKMediaPlayback> delegatePlayer;

@property(nonatomic, weak) id <PlayerControlViewDelagate>delegate;

-(void)updateUIWithPlayStart;

- (void)refreshMediaControl;

@end
