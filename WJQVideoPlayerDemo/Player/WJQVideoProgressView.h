//
//  WJQVideoProgressView.h
//  WJQVideoPlayerDemo
//
//  Created by vidonia on 2019/11/19.
//  Copyright © 2019 vidonia. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WJQVideoProgressViewDelegate <NSObject>

- (void)videoPlay:(BOOL)play;

- (void)sliderChangedValue:(CGFloat)value;

- (void)fullScreen:(BOOL)full;

@end

@interface WJQVideoProgressView : UIView

@property (nonatomic, weak) id<WJQVideoProgressViewDelegate> delegate;

- (void)setupTotalTime:(float)totalTime currentTime:(float)currentTime;

@end

NS_ASSUME_NONNULL_END
