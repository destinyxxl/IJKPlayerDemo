//
//  PlayControllView.m
//  IJKPlayerDemo
//
//  Created by 冯晓林 on 2018/6/8.
//  Copyright © 2018年 FXL. All rights reserved.
//

#import "PlayControllView.h"
#import "Masonry.h"

//#define  MAS_SHORTHAND
//#define  MAS_SHORTHAND_GLOBALS

static const CGFloat margin = 10.0f;
static const CGFloat panelHeight = 50.0f;

@interface PlayControllView()
/** 控制层*/
@property(nonatomic, strong) UIControl *overlayPanel;
/** 上部控制板*/
@property(nonatomic, strong) UIView *topPanel;
/** 下部控制板*/
@property(nonatomic, strong) UIView *bottomPanel;
/** 返回按钮*/
@property(nonatomic, strong) UIButton *backBtn;
/** 锁定屏幕方向按钮 */
@property (nonatomic, strong) UIButton *lockBtn;
/** 播放、暂停按钮 */
@property(nonatomic, strong) UIButton *playBtn;
/** 当前播放时长label */
@property(nonatomic, strong) UILabel *currentTimeLabel;
/** 视频总时长label */
@property(nonatomic, strong) UILabel *totalDurationLabel;
/** 滑杆 */
@property(nonatomic, strong) UISlider *mediaProgressSlider;
/** 全屏按钮 */
@property (nonatomic, strong) UIButton *fullScreenBtn;
/** 缓冲进度条 */
@property (nonatomic, strong) UIProgressView *progressView;
/** 控制层消失时候在底部显示的播放进度progress */
@property (nonatomic, strong) UIProgressView *bottomProgressView;

/**
 上下控制板背景渐变层
 */
@property (nonatomic, strong) CAGradientLayer *gradientLayerTop;
@property (nonatomic, strong) CAGradientLayer *gradientLayerBottom;

@end

@implementation PlayControllView{
    BOOL _isMediaSliderBeingDragged;
    BOOL _isFullScreen;
}

#pragma mark --- 初始化及布局

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addSubviews];
        [self layout];
    }
    return self;
}

-(void)addSubviews{
    
    [self addSubview:self.overlayPanel];
    [self addSubview:self.topPanel];
    [self addSubview:self.bottomPanel];
    
    [self.topPanel addSubview:self.backBtn];
    [self addSubview:self.lockBtn];
    
    [self.bottomPanel addSubview:self.playBtn];
    [self.bottomPanel addSubview:self.currentTimeLabel];
    [self.bottomPanel addSubview:self.progressView];
    [self.bottomPanel addSubview:self.mediaProgressSlider];
    [self.bottomPanel addSubview:self.totalDurationLabel];
    [self.bottomPanel addSubview:self.fullScreenBtn];
}

-(void)layout{
    
    [_overlayPanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    [_topPanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.mas_equalTo(self);
        make.height.mas_equalTo(panelHeight);
    }];

    [_bottomPanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.mas_equalTo(self);
        make.height.mas_equalTo(panelHeight);
    }];
    
    [_backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.centerY.mas_equalTo(_topPanel);
        make.width.height.mas_equalTo(panelHeight);
    }];
    
    [_lockBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(margin*2);
        make.centerY.mas_equalTo(self);
        make.width.height.mas_equalTo(30);
    }];
    
    [_playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.centerY.mas_equalTo(_bottomPanel);
        make.width.height.mas_equalTo(panelHeight);
    }];

    [_currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(_playBtn.mas_right);
        make.centerY.mas_equalTo(_bottomPanel);
    }];

    [_fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.centerY.mas_equalTo(_bottomPanel);
        make.width.height.mas_equalTo(panelHeight);
    }];

    [_totalDurationLabel mas_makeConstraints:^(MASConstraintMaker *make) {

        make.right.mas_equalTo(_fullScreenBtn.mas_left);
        make.centerY.mas_equalTo(_bottomPanel);
    }];

    [_mediaProgressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(_bottomPanel);
        make.left.equalTo(_currentTimeLabel.mas_right).mas_offset(margin);
        make.right.equalTo(_totalDurationLabel.mas_left).mas_offset(-margin);
    }];
    
    [_progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(_mediaProgressSlider);
        make.centerY.mas_equalTo(_mediaProgressSlider).offset(0.5);
    }];
    
}

#pragma mark --- override

-(void)layoutSubviews{
    [super layoutSubviews];
    
    NSLog(@"🐥🐥🐥%s", __func__);
    
//    self.gradientLayerTop.frame = self.topPanel.bounds;
//    self.gradientLayerBottom.frame = self.bottomPanel.bounds;
    
}

#pragma mark --- private method

-(void)hideControlView{
    
    self.overlayPanel.selected = YES;
    [[UIApplication sharedApplication] setStatusBarHidden: _isFullScreen];
    
    [UIView animateWithDuration:0.2 animations:^{
        
        if (self.lockBtn.isSelected == NO) {
            self.lockBtn.hidden = YES;
        }
        self.topPanel.hidden = YES;
        self.bottomPanel.hidden = YES;
    }];
    
    
}

-(void)showControlView{
    
    [[UIApplication sharedApplication] setStatusBarHidden: NO];
    
    [UIView animateWithDuration:0.2 animations:^{
        
        self.lockBtn.hidden = NO;
        self.topPanel.hidden = NO;
        self.bottomPanel.hidden = NO;
    } completion:^(BOOL finished) {
        [self refreshMediaControl];
    }];
}

- (void)cancelDelayedHide
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControlView) object:nil];
}

#pragma mark --- public method

- (void)updateUIWithPlayStart{
    self.playBtn.selected = YES;
}

- (void)refreshMediaControl
{
    // duration
    NSTimeInterval duration = self.delegatePlayer.duration;
    NSTimeInterval playableDuration = self.delegatePlayer.playableDuration;
    NSInteger intDuration = duration + 0.5;
    if (intDuration > 0) {
        self.mediaProgressSlider.maximumValue = duration;
        self.progressView.progress = playableDuration / duration ;
        self.totalDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(intDuration / 60), (int)(intDuration % 60)];
    } else {
        self.totalDurationLabel.text = @"--:--";
        self.mediaProgressSlider.maximumValue = 1.0f;
    }
    
    
    // position
    NSTimeInterval position;
    if (_isMediaSliderBeingDragged) {
        position = self.mediaProgressSlider.value;
    } else {
        position = self.delegatePlayer.currentPlaybackTime;
    }
    NSInteger intPosition = position + 0.5;
    if (intDuration > 0) {
        self.mediaProgressSlider.value = position;
    } else {
        self.mediaProgressSlider.value = 0.0f;
    }
    self.currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(intPosition / 60), (int)(intPosition % 60)];
    
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshMediaControl) object:nil];
    if (!self.bottomPanel.hidden) {
        [self performSelector:@selector(refreshMediaControl) withObject:nil afterDelay:0.5];
    }
}

#pragma mark --- button events

-(void)controlPanelTap:(UIControl *)panel {
    
    if (self.lockBtn.isSelected) {
        self.lockBtn.hidden = !self.lockBtn.isHidden;
        return ;
    }
    
    [self cancelDelayedHide];
    
    panel.selected = !panel.selected;

    if (panel.selected) {
        [self hideControlView];
    } else {
        [self showControlView];
        [self performSelector:@selector(hideControlView) withObject:nil afterDelay:5];
    }
}

- (void)backBtnClick:(UIButton *)sender {
    // 状态条的方向旋转的方向,来判断当前屏幕的方向
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
}

- (void)lockScrrenBtnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.isSelected == YES) {
        [self hideControlView];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.lockBtn.hidden = YES;
        });
    } else {
        [self showControlView];
        [self performSelector:@selector(hideControlView) withObject:nil afterDelay:5];
    }
}

- (void)playBtnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    [self.delegatePlayer isPlaying] ? [self.delegatePlayer pause] : [self.delegatePlayer play];
}

- (void)fullScreenBtnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    sender.selected ? [self.delegate ls_enterFullScreen] : [self.delegate ls_outFullScreen];
    
    _isFullScreen = sender.selected;
}

// slider operation
-(void)didSliderTouchDown{
    _isMediaSliderBeingDragged = YES;
}
-(void)didSliderTouchCancel{
    _isMediaSliderBeingDragged = NO;
}
-(void)didSliderTouchUpOutside{
    _isMediaSliderBeingDragged = NO;
}
-(void)didSliderTouchUpInside{
    self.delegatePlayer.currentPlaybackTime = self.mediaProgressSlider.value;
    _isMediaSliderBeingDragged = NO;
}
-(void)didSliderValueChanged{
    [self refreshMediaControl];
}

#pragma mark --- lazy getter

-(UIControl *)overlayPanel{
    if (!_overlayPanel) {
        _overlayPanel = [[UIControl alloc] init];
        [_overlayPanel addTarget:self action:@selector(controlPanelTap:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _overlayPanel;
}

-(UIView *)topPanel{
    if (!_topPanel) {
        _topPanel = [[UIView alloc] init];
        _topPanel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        [_topPanel.layer addSublayer: self.gradientLayerTop];
    }
    return _topPanel;
}

-(UIView *)bottomPanel{
    if (!_bottomPanel) {
        _bottomPanel = [[UIView alloc] init];
        _bottomPanel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        [_bottomPanel.layer addSublayer: self.gradientLayerBottom];
    }
    return _bottomPanel;
}

//返回
- (UIButton *)backBtn {
    if (!_backBtn) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setImage:[UIImage imageNamed:@"player_back"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

//锁屏按钮
- (UIButton *)lockBtn {
    if (!_lockBtn) {
        _lockBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_lockBtn setImage:[UIImage imageNamed:@"player_unlock-nor"] forState:UIControlStateNormal];
        [_lockBtn setImage:[UIImage imageNamed:@"player_lock-nor"] forState:UIControlStateSelected];
        [_lockBtn addTarget:self action:@selector(lockScrrenBtnClick:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _lockBtn;
}

//播放、暂停
-(UIButton *)playBtn{
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playBtn setImage:[UIImage imageNamed:@"player_play"] forState:UIControlStateNormal];
        [_playBtn setImage:[UIImage imageNamed:@"player_pause"] forState:UIControlStateSelected];
        [_playBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

//当前时间
-(UILabel *)currentTimeLabel{
    if (!_currentTimeLabel) {
        _currentTimeLabel = [[UILabel alloc] init];
        _currentTimeLabel.text = @"00:00";
        _currentTimeLabel.textColor = [UIColor whiteColor];
        _currentTimeLabel.font = [UIFont systemFontOfSize:14];
    }
    return _currentTimeLabel;
}

//滑竿
-(UISlider *)mediaProgressSlider{
    if (!_mediaProgressSlider) {
        _mediaProgressSlider = [[UISlider alloc] init];
        [_mediaProgressSlider setThumbImage:[UIImage imageNamed:@"player_dot"]  forState:UIControlStateNormal];
        _mediaProgressSlider.minimumTrackTintColor = [UIColor orangeColor];
        _mediaProgressSlider.maximumTrackTintColor = [UIColor clearColor];
        [_mediaProgressSlider addTarget:self action:@selector(didSliderTouchDown) forControlEvents:UIControlEventTouchDown];
        [_mediaProgressSlider addTarget:self action:@selector(didSliderTouchCancel) forControlEvents:UIControlEventTouchCancel];
        [_mediaProgressSlider addTarget:self action:@selector(didSliderTouchUpOutside) forControlEvents:UIControlEventTouchUpOutside];
        [_mediaProgressSlider addTarget:self action:@selector(didSliderTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
        [_mediaProgressSlider addTarget:self action:@selector(didSliderValueChanged) forControlEvents:UIControlEventValueChanged];
    }
    return _mediaProgressSlider;
}

- (UIProgressView *)progressView{
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] init];
        _progressView.progressTintColor = [UIColor whiteColor];
    }
    return _progressView;
}

//总时间
-(UILabel *)totalDurationLabel{
    if (!_totalDurationLabel) {
        _totalDurationLabel = [[UILabel alloc] init];
        _totalDurationLabel.text = @"00:00";
        _totalDurationLabel.textColor = [UIColor whiteColor];
        _totalDurationLabel.font = [UIFont systemFontOfSize:14];
    }
    return _totalDurationLabel;
}

//全屏切换按钮
- (UIButton *)fullScreenBtn {
    if (!_fullScreenBtn) {
        _fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullScreenBtn setImage:[UIImage imageNamed:@"player_enterfull"] forState:UIControlStateNormal];
        [_fullScreenBtn setImage:[UIImage imageNamed:@"player_outfull"] forState:UIControlStateSelected];
        [_fullScreenBtn addTarget:self action:@selector(fullScreenBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _fullScreenBtn;
}

-(CAGradientLayer *)gradientLayerTop{
    
    if (!_gradientLayerTop) {
        _gradientLayerTop = [[CAGradientLayer alloc] init];
        _gradientLayerTop.colors = @[(__bridge id)[UIColor blackColor].CGColor,
                                     (__bridge id)[UIColor clearColor].CGColor];
    }
    return _gradientLayerTop;
}

-(CAGradientLayer *)gradientLayerBottom{
    if (!_gradientLayerBottom) {
        _gradientLayerBottom = [[CAGradientLayer alloc] init];
        _gradientLayerBottom.colors = @[(__bridge id)[UIColor clearColor].CGColor,
                                        (__bridge id)[UIColor blackColor].CGColor];
    }
    return _gradientLayerBottom;
}

@end
