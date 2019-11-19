//
//  YTScanPicVideoView.m
//  YuanTu
//
//  Created by vidonia on 2019/11/12.
//  Copyright © 2019 panweijian. All rights reserved.
//

#import "YTScanPicVideoView.h"
#import <AVFoundation/AVFoundation.h>
#import <Lottie/LOTAnimationView.h>

@interface YTScanPicVideoLoadingView : UIView

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) LOTAnimationView *animationView;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation YTScanPicVideoLoadingView

- (instancetype)init {
    
    if (self = [super init]) {
    
        self.backgroundColor = [UIColor colorWithHexString:@"#760808"];
        self.frame = (CGRectMake(0, 0, ScreenWidth, ScreenHeight));
        
        self.closeButton = [UIButton yt_buttonWithBackgroundImage:@"关闭icon" superView:self constraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(30);
            make.left.equalTo(self).offset(15);
            make.top.equalTo(self).offset(kStatusBarHeight+6);
        }];
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"AR_Festival" ofType:@"json"];
        LOTAnimationView *animationView = [LOTAnimationView animationWithFilePath:filePath];
        animationView.frame = CGRectMake((ScreenWidth - 245)/ 2, (ScreenHeight - 245)/ 2, 245, 245);
        animationView.contentMode = UIViewContentModeScaleAspectFit;
        animationView.loopAnimation = YES;
        [self addSubview:animationView];
        [animationView play];
        self.animationView = animationView;
        
        self.progressLabel = [UILabel yt_labelWithTextColor:[UIColor colorWithHexString:@"#F4D484"] font:[UIFont boldSystemFontOfSize:22] superView:self.animationView constraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.animationView).offset(127.5);
            make.centerX.equalTo(self.animationView);
        }];
        
        self.progressLabel.text = @"20%";
        
        __block NSInteger progress = 20;
        
        NSInteger highValue = arc4random() % 6 + 93;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES block:^(NSTimer * _Nonnull timer) {
            progress += arc4random() % 10 + 15;
            if (progress > highValue) {
                progress = highValue;
            }
            self.progressLabel.text = [NSString stringWithFormat:@"%ld%%", (long)progress];
        }];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
    
    return self;
}

- (void)startAnimate {
    
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    
    [UIApplication sharedApplication].keyWindow.userInteractionEnabled = YES;
}

- (void)stopAnimate:(void (^)(void))hander {
    
    self.progressLabel.text = @"99%";
    [self.timer invalidate];
    self.timer = nil;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.animationView pause];
        [self removeFromSuperview];
        hander();
    });

}

@end

// 播放器的几种状态
typedef NS_ENUM(NSInteger, YTScanPicVideoState) {
    YTScanPicVideoStateWaiting,    // 等待播放(视频可以播放了)
    YTScanPicVideoStateBuffering,  // 缓冲中
    YTScanPicVideoStatePlaying,    // 播放中
    YTScanPicVideoStatePause,      // 暂停播放
    YTScanPicVideoStateEnd,        // 播放完成
    YTScanPicVideoStateStopped,    // 停止播放
    YTScanPicVideoStateFailed,     // 播放失败
};

@interface YTScanPicVideoView ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, strong) YTScanPicVideoLoadingView *loadingView;

@property (nonatomic, assign) YTScanPicVideoState playState;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation YTScanPicVideoView

- (instancetype)initWithUrl:(NSString *)url {
    
    if (self = [super init]) {
        
        self.loadingView = [[YTScanPicVideoLoadingView alloc] init];
        [self.loadingView startAnimate];
        [self.loadingView.closeButton addTarget:self action:@selector(loadCloseButtonClick) forControlEvents:(UIControlEventTouchUpInside)];

        
        NSURL *playUrl = [NSURL URLWithString:url];
        self.playerItem = [AVPlayerItem playerItemWithURL:playUrl];
        
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        
        // 设置横屏
        [self setOrientationLandscapeConstraint:UIInterfaceOrientationLandscapeRight];
        
        [self addObservers];
        [self addNotifications];

        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(countDown) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        
        [[UIApplication sharedApplication].keyWindow bringSubviewToFront:self.loadingView];
    }
    
    return self;
}

- (void)countDown {
    
    if (self.playState == YTScanPicVideoStatePlaying) {
        
        __weak typeof(self) weakSelf = self;
        
        [self.loadingView stopAnimate:^{
            
            self.backgroundColor = [UIColor blackColor];
            [weakSelf.layer addSublayer:weakSelf.playerLayer];
            
            weakSelf.closeButton = [UIButton yt_buttonWithBackgroundImage:@"关闭icon" superView:weakSelf constraints:^(MASConstraintMaker *make) {
                make.size.mas_equalTo(30);
                make.top.equalTo(weakSelf).offset(20);
                if (IS_IPHONE_X) {
                    make.left.equalTo(weakSelf).offset(kTopHeight+kScreenAutoLayoutScaleCeil(35));
                } else {
                    make.left.equalTo(weakSelf).offset(26);
                }
            }];
            
            [weakSelf.closeButton addTarget:weakSelf action:@selector(closeButtonClick) forControlEvents:(UIControlEventTouchUpInside)];
            
            [weakSelf.player play];
            [weakSelf.timer invalidate];
            weakSelf.timer = nil;
            
        }];
    
    }
}

- (void)destroyPlayer {
    
    [self.player pause];
    [self removeFromSuperview];
    [self removeAllObservers];
    [self removeNotifications];
    
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
    [UIApplication sharedApplication].statusBarHidden = NO;

    [self.playerLayer removeFromSuperlayer];
    [self removeFromSuperview];
    
    self.playerLayer = nil;
    self.player = nil;
    self.playerItem = nil;
}

#pragma mark - Observers

- (void)addObservers {
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeAllObservers {
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"status"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        
        NSString *keep = [change yt_safeObjectForKey:@"new"];
        
        if ([keep boolValue] && (self.player.timeControlStatus == AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate || self.player.timeControlStatus == AVPlayerTimeControlStatusPaused)) {
            if (self.playState == YTScanPicVideoStatePlaying) {
                [self.player play];
            }
            self.playState = YTScanPicVideoStatePlaying;
        }
    
    } else  if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        
        NSString *empty = [change yt_safeObjectForKey:@"new"];
        
        if ([empty boolValue]) {
            self.playState = YTScanPicVideoStateBuffering;
        }
        
    } else if ([keyPath isEqualToString:@"status"]) {
        
        NSString *status = [change yt_safeObjectForKey:@"new"];
        if ([status integerValue] == AVPlayerItemStatusReadyToPlay) {
            self.playState = YTScanPicVideoStateWaiting;
        }
    }
}

#pragma mark - Notification

- (void)addNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
}

- (void)removeNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)videoPlayDidEnd:(NSNotification *)notification {
    self.playState = YTScanPicVideoStateEnd;
    
    AVPlayerItem *item = self.player.currentItem;
    [item seekToTime:kCMTimeZero];
    [self.player play];
}

#pragma mark - SettingLandscape

- (void)setOrientationLandscapeConstraint:(UIInterfaceOrientation)orientation {
    
    [UIApplication sharedApplication].statusBarHidden = YES;

    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow addSubview:self];
    
    [UIView animateWithDuration:0.25 animations:^{
        self.transform = CGAffineTransformMakeRotation(M_PI / 2);
    }];
    
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:NO];

    [self mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(ScreenHeight));
        make.height.equalTo(@(ScreenWidth));
        make.center.equalTo([UIApplication sharedApplication].keyWindow);
    }];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    self.playerLayer.frame = self.bounds;
}

#pragma mark - Action

- (void)closeButtonClick {
    if ([self.delegate respondsToSelector:@selector(scanPicViewClose)]) {
        [self.delegate scanPicViewClose];
    }
}

- (void)loadCloseButtonClick {
    if ([self.delegate respondsToSelector:@selector(scanPicViewClose)]) {
        [self.delegate scanPicViewClose];
    }
    [self.loadingView removeFromSuperview];
}

#pragma mark - Setter & Getter

- (void)setPlayState:(YTScanPicVideoState)playState {
    _playState = playState;
}


@end
