//
//  XLCameraToolView.h
//  XLCamera
//
//  Created by Facebook on 2018/1/10.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CameraToolViewDelegate <NSObject>
/**
 单击事件，拍照
 */
- (void)onTakePicture;
/**
 开始录制
 */
- (void)onStartRecord;
/**
 结束录制
 */
- (void)onFinishRecord;
/**
 重新拍照或录制
 */
- (void)onRetake;
/**
 点击确定
 */
- (void)onOkClick;
/**
 点击取消
 */
- (void)onDismiss;

@end

@interface XLCameraToolView : UIView

@end
