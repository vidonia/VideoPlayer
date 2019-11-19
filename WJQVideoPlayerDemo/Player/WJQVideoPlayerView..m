//
//  WJQVideoPlayerView.m
//  YuanTu
//
//  Created by vidonia on 2019/11/12.
//  Copyright © 2019 panweijian. All rights reserved.
//

#import "WJQVideoPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import "WJQVideoProgressView.h"
#import "Masonry.h"

// 播放器的几种状态
typedef NS_ENUM(NSInteger, WJQVideoPlayerState) {
    WJQVideoPlayerStateWaiting,    // 等待播放(视频可以播放了)
    WJQVideoPlayerStateBuffering,  // 缓冲中
    WJQVideoPlayerStatePlaying,    // 播放中
    WJQVideoPlayerStatePause,      // 暂停播放
    WJQVideoPlayerStateEnd,        // 播放完成
    WJQVideoPlayerStateStopped,    // 停止播放
    WJQVideoPlayerStateFailed,     // 播放失败
};

@interface WJQVideoPlayerView () <WJQVideoProgressViewDelegate>

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) WJQVideoProgressView *progressView;

@property (nonatomic, assign) WJQVideoPlayerState playState;

@property (nonatomic, assign) UIInterfaceOrientation currentOrientation; //当前的方向；
@property (nonatomic, strong) id timeObserve; //定时观察者

@property (nonatomic, assign) CGRect initFrame; // 初始frame
@property (nonatomic, strong) UIView *initSuperView; // 父控件
@property (nonatomic, assign) BOOL isFullScreen;

@end

@implementation WJQVideoPlayerView

- (instancetype)initWithFrame:(CGRect)frame url:(NSString *)url superView:(UIView *)superView {
    
    if (self = [super initWithFrame:frame]) {
        
        self.initFrame = frame;
        self.initSuperView = superView;
        
        self.backgroundColor = [UIColor blackColor];
        
        NSURL *playUrl = [NSURL URLWithString:url];
        self.playerItem = [AVPlayerItem playerItemWithURL:playUrl];
        
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        self.playerLayer.frame = self.bounds;
        [self.layer addSublayer:self.playerLayer];
        
        self.progressView = [[WJQVideoProgressView alloc] init];
        [self addSubview:self.progressView];
        [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.equalTo(self);
            make.left.bottom.equalTo(self);
        }];
        self.progressView.delegate = self;
        self.progressView.hidden = YES;
        
        [self addObservers];
        [self addNotifications];
        
        UITapGestureRecognizer *tapSelf = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapPlayer)];
        [self addGestureRecognizer:tapSelf];
        
    }
    
    return self;
}

- (void)destroyPlayer {
    
    [self.player pause];
    [self removeFromSuperview];
    [self removeAllObservers];
    [self removeNotifications];
    
    [self.playerLayer removeFromSuperlayer];
    [self removeFromSuperview];
    
    self.playerLayer = nil;
    self.player = nil;
    self.playerItem = nil;
}

- (void)pause {
    [self.player pause];
    self.playState = WJQVideoPlayerStatePause;
}

- (void)play {
    if (self.playState == WJQVideoPlayerStatePause) {
        self.playState = WJQVideoPlayerStatePlaying;
    }
}

#pragma mark - Observers

- (void)addObservers {
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
//    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    __weak typeof(self) weakSelf = self;
    self.timeObserve = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds(weakSelf.playerItem.duration);
        [weakSelf.progressView setupTotalTime:total currentTime:current];
    }];
    
}

- (void)removeAllObservers {
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"status"];
//    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    if (self.timeObserve) {
        self.timeObserve = nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        
        NSString *keep = [change objectForKey:@"new"];
        
        if ([keep boolValue] && (self.playState == WJQVideoPlayerStateWaiting || self.playState == WJQVideoPlayerStateBuffering)) {
            self.playState = WJQVideoPlayerStatePlaying;
        }
    
    } else  if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        
        NSString *empty = [change objectForKey:@"new"];
        
        if ([empty boolValue]) {
            self.playState = WJQVideoPlayerStateBuffering;
        }
        
    } else if ([keyPath isEqualToString:@"status"]) {
        
        NSString *status = [change objectForKey:@"new"];
        if ([status integerValue] == AVPlayerItemStatusReadyToPlay) {
            self.playState = WJQVideoPlayerStateWaiting;
        } else {
            self.playState = WJQVideoPlayerStateFailed;
        }
        
    }
    
//    else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
//        // 计算缓冲进度
//        NSTimeInterval timeInterval = [self availableDuration];
//        CMTime duration             = self.playerItem.duration;
//        CGFloat totalDuration       = CMTimeGetSeconds(duration);
//        if (isnan(timeInterval)) {
//            timeInterval = 0;
//        }
//
//        NSLog(@"%f %f", totalDuration, timeInterval);
//
//    }
}

#pragma mark - Notification

- (void)addNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    
    //开启
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    //注册屏幕旋转通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:[UIDevice currentDevice]];
    //APP运行状态通知，将要被挂起
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    // app进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterPlayground:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
}

- (void)removeNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)videoPlayDidEnd:(NSNotification *)notification {
    self.playState = WJQVideoPlayerStateEnd;
    
    AVPlayerItem *item = self.player.currentItem;
    [item seekToTime:kCMTimeZero];
    [self.player play];
}

- (void)appDidEnterBackground:(NSNotification *)notification {
    // 将要挂起，停止播放
    [self pause];
    
}
- (void)appDidEnterPlayground:(NSNotification *)notification {
    // 继续播放
    [self play];
}

- (void)orientChange:(NSNotification *)notification {
    
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    
    if (self.isFullScreen) {
        
        if (orientation == UIDeviceOrientationPortrait) {
            
            [self setOrientationPortraitConstraint:UIInterfaceOrientationPortrait];
        }
        
    } else {
        
        if (orientation == UIDeviceOrientationLandscapeLeft) {
            
            [self setOrientationLandscapeConstraint:UIInterfaceOrientationLandscapeRight];
            
            
        } else if (orientation == UIDeviceOrientationLandscapeRight) {
            
            [self setOrientationLandscapeConstraint:UIInterfaceOrientationLandscapeLeft];
            
            
        }
    }

}

#pragma mark - SettingLandscape

- (void)setOrientationLandscapeConstraint:(UIInterfaceOrientation)orientation {
    
    if (self.currentOrientation == orientation) {
        return;
    }
    
    self.isFullScreen = YES;
    
    [self removeFromSuperview];
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow addSubview:self];
    
    if (orientation == UIInterfaceOrientationLandscapeRight) {
        
        [UIView animateWithDuration:0.25 animations:^{
            self.transform = CGAffineTransformMakeRotation(M_PI / 2);
        }];
        
    } else {
        
        [UIView animateWithDuration:0.25 animations:^{
            self.transform = CGAffineTransformMakeRotation(-M_PI / 2);
        }];
        
    }
    
    [self mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo([UIScreen mainScreen].bounds.size.height);
        make.height.mas_equalTo([UIScreen mainScreen].bounds.size.width);
        make.center.equalTo([UIApplication sharedApplication].keyWindow);
    }];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    self.playerLayer.frame = self.bounds;
    
    self.currentOrientation = orientation;
}

- (void)setOrientationPortraitConstraint:(UIInterfaceOrientation)orientation {
    
    if (orientation == self.currentOrientation) {
        return;
    }
    
    self.isFullScreen = NO;
    
    // 还原
    [UIView animateWithDuration:0.25 animations:^{
        self.transform = CGAffineTransformMakeRotation(0);
    }];
    
    
    if (self.initSuperView) {
        [self removeFromSuperview];
        [self.initSuperView addSubview:self];

        [self mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(self.initFrame.size.width);
            make.height.mas_equalTo(self.initFrame.size.height);
            make.left.mas_equalTo(self.initFrame.origin.x);
            make.top.mas_equalTo(self.initFrame.origin.y);
        }];
    }
    
    
    self.currentOrientation = orientation;
    [self setNeedsLayout];
//    [self layoutIfNeeded];
    
    self.playerLayer.frame = self.bounds;
    
}

#pragma mark - Action

- (void)singleTapPlayer {
    self.progressView.hidden = !self.progressView.hidden;
}

#pragma mark - WJQVideoProgressViewDelegate

- (void)videoPlay:(BOOL)play {
    if (play) {
        [self play];
    } else {
        [self pause];
    }
}

- (void)fullScreen:(BOOL)full {
    if (full) {
        [self setOrientationLandscapeConstraint:(UIInterfaceOrientationLandscapeRight)];
    } else {
        [self setOrientationPortraitConstraint:(UIInterfaceOrientationPortrait)];
    }
}

- (void)sliderChangedValue:(CGFloat)value {
    
    [self pause];
    
    CMTime time = self.player.currentItem.duration;
    float totalTime = CMTimeGetSeconds(time);
    
    [self.player seekToTime:CMTimeMake(value * totalTime, 1) completionHandler:^(BOOL finished) {
        if (finished) {
            [self play];
        }
    }];
}

#pragma mark - Setter & Getter

- (void)setPlayState:(WJQVideoPlayerState)playState {
    _playState = playState;
    if (playState == WJQVideoPlayerStatePlaying) {
        [self.player play];
    }
}

#pragma mark - Private

- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    CMTimeRange timeRange     = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds        = CMTimeGetSeconds(timeRange.start);
    float durationSeconds     = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result     = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

@end
