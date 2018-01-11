//
//  XLSCameraManager.h
//  XLCamera
//
//  Created by Facebook on 2018/1/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface XLSCameraManager : NSObject

/**
 初始化
 */
- (instancetype)initWithSuperView:(UIView *)superView;

/**
 开启摄像
 */
- (void)openVideo;

/**
 关闭摄像
 */
- (void)closeVideo;

/**
 拍照
 */
- (void)takePicture;

/**
 取消
 */
- (void)cannel;

/**
 切换摄像头
 */
- (void)exchangeCamera;

/**
 获取原图
 */
- (UIImage *)getOriginalImage;

@end
