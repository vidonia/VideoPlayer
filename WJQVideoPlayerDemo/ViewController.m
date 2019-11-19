//
//  ViewController.m
//  WJQVideoPlayerDemo
//
//  Created by vidonia on 2019/11/18.
//  Copyright © 2019 vidonia. All rights reserved.
//

#import "ViewController.h"
#import "WJQVideoPlayerView.h"

@interface ViewController ()

@property (nonatomic, strong) WJQVideoPlayerView *playView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    NSString *url = @"http://wvideo.spriteapp.cn/video/2016/0328/56f8ec01d9bfe_wpd.mp4";
    
    self.playView = [[WJQVideoPlayerView alloc] initWithFrame:(CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 200)) url:url];
    [self.view addSubview:self.playView];
    
}


@end
