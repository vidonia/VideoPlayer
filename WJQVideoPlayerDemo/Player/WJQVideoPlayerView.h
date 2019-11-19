//
//  WJQVideoPlayerView.h
//  YuanTu
//
//  Created by vidonia on 2019/11/12.
//  Copyright © 2019 panweijian. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WJQVideoPlayerViewDelegate <NSObject>

- (void)scanPicViewClose;

@end

@interface WJQVideoPlayerView : UIView

@property (nonatomic, weak) id<WJQVideoPlayerViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame url:(NSString *)url;

- (void)destroyPlayer;

- (void)pause;

- (void)play;

@end

NS_ASSUME_NONNULL_END
