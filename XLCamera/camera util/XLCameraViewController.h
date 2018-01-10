//
//  XLCameraViewController.h
//  XLCamera
//
//  Created by Facebook on 2018/1/10.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XLConst.h"

/*!
 * 相机类
 */
@interface XLCameraViewController : UIViewController
/*!
 * 是否允许录制视频
 */
@property (nonatomic, assign) BOOL allowRecordVideo;
/*!
 * 视频输入尺寸类型
 */
@property (nonatomic, assign) XLCaptureSessionPreset sessionPreset;
/*!
 * 导出视频类型
 */
@property (nonatomic, assign) XLExportVideoType videoType;
/*!
 * 录制视频时候进度条颜色
 */
@property (nonatomic, strong) UIColor *circleProgressColor;
/*!
 * block回调
 */
@property (nonatomic, copy) void (^doneCompletBlock)(UIImage *image, NSURL *videoUrl);

@end
