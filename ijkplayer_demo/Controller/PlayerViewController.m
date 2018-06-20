//
//  PlayerViewController.m
//  IJKPlayerDemo
//
//  Created by 冯晓林 on 2018/6/7.
//  Copyright © 2018年 FXL. All rights reserved.
//

#import "PlayerViewController.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#import "PlayControllView.h"
#import "ContainerView.h"
#import "masonry.h"
#import "PlayerControlViewDelagate.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface PlayerViewController () <PlayerControlViewDelagate>

@property(nonatomic, strong) ContainerView *container;

@property(nonatomic, strong) NSURL *url;
@property(nonatomic, retain) id<IJKMediaPlayback> player;

@property(nonatomic, strong) PlayControllView *controlView;

@end



@implementation PlayerViewController

#pragma mark --- LifeCircle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *status = [[UIView alloc] init];
    status.backgroundColor = [UIColor blackColor];
    status.frame = CGRectMake(0, 0, SCREEN_WIDTH, 20);
    [self.view addSubview:status];
    
    self.container = [[ContainerView alloc] init];
    self.container.backgroundColor = [UIColor greenColor];
    self.container.frame = CGRectMake(0, 20, SCREEN_WIDTH, 230);
    
    [self.view addSubview:self.container];
    
    NSString *url = @"http://wvideo.spriteapp.cn/video/2018/0422/6c9d9666-45c9-11e8-bb9f-1866daeb0df1_wpd.mp4";

    self.url = [NSURL URLWithString:url];

    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    self.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:self.url withOptions:options];
    self.player.shouldAutoplay = YES;
//    self.player.playbackVolume = 0;
    self.player.view.backgroundColor = [UIColor blackColor];
    [self.container addSubview:self.player.view];

    _controlView = [[PlayControllView alloc] init];
    _controlView.delegate = self;
    _controlView.delegatePlayer = self.player;
    _controlView.frame = self.container.bounds;
    [self.container addSubview:_controlView];
    [@[self.player.view, _controlView] mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.container);
    }];
    
    [_controlView refreshMediaControl];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self installMovieNotificationObservers];
    
    [self.player prepareToPlay];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.player shutdown];
    [self removeMovieNotificationObservers];
}

#pragma mark --- controlEvents
- (void)ls_enterFullScreen {
    NSLog(@"before --- %@", NSStringFromCGRect(_controlView.frame));
    
    if (self.container.state != ViewStateSmall) {
        return;
    }
    
    self.container.state = ViewStateAnimating;
    
    /*
     * 记录进入全屏前的parentView和frame
     */
    self.container.movieViewParentView = self.container.superview;
    self.container.movieViewFrame = self.container.frame;
    
    /*
     * container移到window上
     */
    UIView *keyWindow = [UIApplication sharedApplication].keyWindow;
    CGRect rectInWindow = [self.container convertRect:self.container.bounds toView: keyWindow];
    self.container.frame = rectInWindow;
    [keyWindow addSubview:self.container];
    
    CGRect frame = keyWindow.frame;
    /*
     * 执行动画
     */
    [UIView animateWithDuration:0.4 animations:^{
        self.container.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.container.frame = frame;
        [self.container layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.container.state = ViewStateFullScreen;
        [self refreshStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
    }];
    

    NSLog(@"after --- %@", NSStringFromCGRect(_controlView.frame));
}

- (void)ls_outFullScreen {
    
    if (self.container.state != ViewStateFullScreen) {
        return;
    }
    
    self.container.state = ViewStateAnimating;
    
    CGRect frame = [[UIApplication sharedApplication].keyWindow convertRect:self.container.frame toView:self.container.movieViewParentView];
    
    self.container.frame = frame;
    [self.container.movieViewParentView addSubview:self.container];
    
    [UIView animateWithDuration:0.4 animations:^{
        self.container.transform = CGAffineTransformIdentity;
        self.container.frame = self.container.movieViewFrame;
        [self.container layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.container.state = ViewStateSmall;
        [self refreshStatusBarOrientation: UIInterfaceOrientationPortrait];
    }];
}

- (void)refreshStatusBarOrientation:(UIInterfaceOrientation)interfaceOrientation {
    [[UIApplication sharedApplication] setStatusBarOrientation:interfaceOrientation animated: NO];
}

#pragma mark --- notifaction method

- (void)loadStateDidChange:(NSNotification*)notification
{
    //    MPMovieLoadStateUnknown        = 0,
    //    MPMovieLoadStatePlayable       = 1 << 0,
    //    MPMovieLoadStatePlaythroughOK  = 1 << 1, // Playback will be automatically started in this state when shouldAutoplay is YES
    //    MPMovieLoadStateStalled        = 1 << 2, // Playback will be automatically paused in this state, if started
    
    IJKMPMovieLoadState loadState = _player.loadState;
    
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStatePlaythroughOK: %d\n", (int)loadState);
    } else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
    } else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

- (void)moviePlayBackDidFinish:(NSNotification*)notification
{
    //    MPMovieFinishReasonPlaybackEnded,
    //    MPMovieFinishReasonPlaybackError,
    //    MPMovieFinishReasonUserExited
    int reason = [[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    
    switch (reason)
    {
        case IJKMPMovieFinishReasonPlaybackEnded:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);
            break;
            
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification
{
    NSLog(@"mediaIsPreparedToPlayDidChange\n");
}

- (void)moviePlayBackStateDidChange:(NSNotification*)notification
{
    //    MPMoviePlaybackStateStopped,
    //    MPMoviePlaybackStatePlaying,
    //    MPMoviePlaybackStatePaused,
    //    MPMoviePlaybackStateInterrupted,
    //    MPMoviePlaybackStateSeekingForward,
    //    MPMoviePlaybackStateSeekingBackward
    
    switch (_player.playbackState)
    {
        case IJKMPMoviePlaybackStateStopped: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: stoped", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStatePlaying: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: playing", (int)_player.playbackState);
            [self.controlView updateUIWithPlayStart];
            break;
        }
        case IJKMPMoviePlaybackStatePaused: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: paused", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStateInterrupted: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: interrupted", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: seeking", (int)_player.playbackState);
            break;
        }
        default: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)_player.playbackState);
            break;
        }
    }
}

#pragma mark --- system method override
- (BOOL)shouldAutorotate {
    return NO;
}

#pragma mark Install Movie Notifications

/* Register observers for the various movie object notifications. */
-(void)installMovieNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_player];
}

#pragma mark Remove Movie Notification Handlers

/* Remove the movie notification observers from the movie object. */
-(void)removeMovieNotificationObservers
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerLoadStateDidChangeNotification object:_player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackDidFinishNotification object:_player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification object:_player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:_player];
}

@end
