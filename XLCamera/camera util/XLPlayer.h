//
//  XLPlayer.h
//  XLCamera
//
//  Created by Facebook on 2018/1/10.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XLPlayer : UIView
/**
 视频播放地址
 */
@property (nonatomic, strong) NSURL *videoUrl;
/**
 开始播放
 */
- (void)play;

/**
 暂停
 */
- (void)pause;

/**
 重置
 */
- (void)reset;

/**
 是否正在播放
 */
- (BOOL)isPlay;

@end
