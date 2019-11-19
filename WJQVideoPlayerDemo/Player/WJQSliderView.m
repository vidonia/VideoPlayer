//
//  WJQSliderView.m
//  WJQVideoPlayerDemo
//
//  Created by vidonia on 2019/11/19.
//  Copyright © 2019 vidonia. All rights reserved.
//

#import "WJQSliderView.h"
#import "Masonry.h"

@interface WJQSliderView ()

/**
 已播放进度条
 */
@property (nonatomic, strong) UIView *leftView;

/**
 未播放进度条
 */
@property (nonatomic, strong) UIView *rightView;

/**
 滑块
 */
@property (nonatomic, strong) UIView *blockView;

/**
 上一次偏移量
 */
@property (nonatomic, assign) CGFloat lastOffsetX;

/**
 记录滑动value
 */
@property (nonatomic, assign) CGFloat tempValue;

/**
 开始拖动
 */
@property (nonatomic, assign) BOOL beginPan;

@end

@implementation WJQSliderView

- (instancetype)init {
    
    if (self = [super init]) {
        
        self.rightView = [[UIView alloc] init];
        [self addSubview:self.rightView];
        self.rightView.layer.cornerRadius = 2;
        self.rightView.backgroundColor = [UIColor colorWithRed:228/255.0 green:232/255.0 blue:241/255.0 alpha:1];
        [self.rightView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(0);
            make.right.equalTo(self).offset(0);
            make.centerY.equalTo(self);
            make.height.mas_offset(10);
        }];
        
        self.leftView = [[UIView alloc] init];
        [self addSubview:self.leftView];
        self.leftView.layer.cornerRadius = 2;
        self.leftView.backgroundColor = [UIColor colorWithRed:137/255.0 green:167/255.0 blue:220/255.0 alpha:1];
        [self.leftView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(0);
            make.centerY.equalTo(self);
            make.height.mas_offset(10);
        }];
        
        self.blockView = [[UIView alloc] init];
        [self addSubview:self.blockView];
        self.blockView.layer.cornerRadius = 2;
        self.blockView.backgroundColor = [UIColor colorWithRed:48/255.0 green:122/255.0 blue:255/255.0 alpha:1];
        [self.blockView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.leftView.mas_right).offset(-2);
            make.centerY.equalTo(self.rightView.mas_centerY);
            make.height.mas_offset(20);
            make.width.mas_offset(10);
        }];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(blobkViewPanned:)];
        [self.blockView addGestureRecognizer:pan];
        
    }
    
    return self;
}

- (void)blobkViewPanned:(UIPanGestureRecognizer *)gesture {
    
    CGPoint point = [gesture translationInView:self];
    
    // 本次移动的位置
    CGFloat movingX = point.x - self.lastOffsetX;
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.beginPan = YES;
        self.tempValue = self.value;
    }
    
    // 移动前的偏移量
    CGFloat movedX = self.tempValue * self.frame.size.width;
    
    // 总共移动的偏移量
    CGFloat offsetX = movingX + movedX;
    CGFloat value = offsetX / self.frame.size.width;
    
    self.tempValue = value;
    self.value = value;
    [self sendActionsForControlEvents:(UIControlEventValueChanged)];
    
    self.lastOffsetX = point.x;
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        self.beginPan = NO;
        self.lastOffsetX = 0;
    }
}

- (void)setValue:(CGFloat)value {

    if (self.beginPan) {
        value = self.tempValue;
    }
    
    value = value > 0.97 ? 0.97 : value;
    
    value = value < 0 ? 0 : value;
    
    if (value >= 0 && value <= 1) {
        
        [self.leftView mas_updateConstraints:^(MASConstraintMaker *make) {
            
            make.width.mas_equalTo(self.frame.size.width*value);
            
        }];
        
        _value = value;
        
    }
    
}

@end
