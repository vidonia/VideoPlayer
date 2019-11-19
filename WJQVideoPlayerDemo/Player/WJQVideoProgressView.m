//
//  WJQVideoProgressView.m
//  WJQVideoPlayerDemo
//
//  Created by vidonia on 2019/11/19.
//  Copyright © 2019 vidonia. All rights reserved.
//

#import "WJQVideoProgressView.h"

#import "WJQSliderView.h"
#import "Masonry.h"

@interface WJQVideoProgressView ()

@property (nonatomic, strong) UILabel *currentTimeLabel;
@property (nonatomic, strong) UILabel *totalTimeLabel;
@property (nonatomic, strong) WJQSliderView *silderView;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *fullScreenButton;

@end

@implementation WJQVideoProgressView

- (instancetype)init {
    if (self = [super init]) {
        
        self.playButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [self.playButton setBackgroundImage:[UIImage imageNamed:@"play"] forState:(UIControlStateNormal)];
        [self.playButton setBackgroundImage:[UIImage imageNamed:@"pause"] forState:(UIControlStateSelected)];
        self.playButton.selected = YES;
        [self addSubview:self.playButton];
        [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(45);
            make.center.equalTo(self);
        }];
        
        
        UIView *bottomView = [UIView new];
        bottomView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        [self addSubview:bottomView];
        [bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self);
            make.height.mas_equalTo(50);
        }];
        
        self.currentTimeLabel = [UILabel new];
        self.currentTimeLabel.textColor = [UIColor whiteColor];
        self.currentTimeLabel.font = [UIFont systemFontOfSize:12];
        self.currentTimeLabel.text = @"00:00:00";
        self.currentTimeLabel.textAlignment = NSTextAlignmentCenter;
        [bottomView addSubview:self.currentTimeLabel];
        [self.currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(bottomView);
            make.centerY.equalTo(bottomView);
            make.width.mas_equalTo(70);
        }];
        
        self.fullScreenButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [self.fullScreenButton setBackgroundImage:[UIImage imageNamed:@"btn_zoom_out"] forState:(UIControlStateNormal)];
        [self.fullScreenButton setBackgroundImage:[UIImage imageNamed:@"btn_zoom_in"] forState:(UIControlStateSelected)];
        [bottomView addSubview:self.fullScreenButton];
        [self.fullScreenButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(16);
            make.centerY.equalTo(bottomView);
            make.right.equalTo(bottomView).mas_offset(-15);
        }];


        self.totalTimeLabel = [UILabel new];
        self.totalTimeLabel.textColor = [UIColor whiteColor];
        self.totalTimeLabel.font = [UIFont systemFontOfSize:12];
        self.totalTimeLabel.text = @"00:00:00";
        self.totalTimeLabel.textAlignment = NSTextAlignmentCenter;
        [bottomView addSubview:self.totalTimeLabel];
        [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.fullScreenButton.mas_left);
            make.centerY.equalTo(bottomView);
            make.width.mas_equalTo(70);
        }];
        
        self.silderView = [[WJQSliderView alloc] init];
        [bottomView addSubview:self.silderView];
        [self.silderView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.currentTimeLabel.mas_right).offset(8);
            make.right.equalTo(self.totalTimeLabel.mas_left).offset(-8);
            make.height.equalTo(bottomView);
        }];
        
        [self.fullScreenButton addTarget:self action:@selector(fullScreenButtonClick) forControlEvents:(UIControlEventTouchUpInside)];
        [self.playButton addTarget:self action:@selector(playOrPause) forControlEvents:(UIControlEventTouchUpInside)];
        [self.silderView addTarget:self action:@selector(sliderChanged) forControlEvents:(UIControlEventValueChanged)];
        
    }
    return self;
}

- (void)playOrPause {
    self.playButton.selected = !self.playButton.selected;
    if ([self.delegate respondsToSelector:@selector(videoPlay:)]) {
        [self.delegate videoPlay:self.playButton.selected];
    }
}

- (void)fullScreenButtonClick {
    self.fullScreenButton.selected = !self.fullScreenButton.selected;
    if ([self.delegate respondsToSelector:@selector(fullScreen:)]) {
        [self.delegate fullScreen:self.fullScreenButton.selected];
    }
}

- (void)sliderChanged {
    if ([self.delegate respondsToSelector:@selector(sliderChangedValue:)]) {
        [self.delegate sliderChangedValue:self.silderView.value];
    }
}


- (void)setupTotalTime:(float)totalTime currentTime:(float)currentTime {
    self.silderView.value = currentTime/totalTime;
    self.currentTimeLabel.text = [self _getTimeString:currentTime];
    self.totalTimeLabel.text = [self _getTimeString:totalTime];
}

- (NSString *)_getTimeString:(NSTimeInterval)timeInterval{
    NSInteger miniutC = timeInterval / 60;
    NSInteger hourC = miniutC / 60;
    NSInteger secondC = ((NSInteger)timeInterval) % 60;
    return [NSString stringWithFormat:@"%02zd:%02zd:%02zd", hourC, miniutC, secondC];
}

@end
