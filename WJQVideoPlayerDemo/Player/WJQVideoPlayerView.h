//
//  YTScanPicVideoView.h
//  YuanTu
//
//  Created by vidonia on 2019/11/12.
//  Copyright © 2019 panweijian. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol YTScanPicVideoViewDelegate <NSObject>

- (void)scanPicViewClose;

@end

@interface YTScanPicVideoView : UIView

@property (nonatomic, weak) id<YTScanPicVideoViewDelegate> delegate;

- (instancetype)initWithUrl:(NSString *)url;

- (void)destroyPlayer;

@end

NS_ASSUME_NONNULL_END
