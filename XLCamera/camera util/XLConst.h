//
//  XLConst.h
//  XLCamera
//
//  Created by Facebook on 2018/1/10.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#ifndef XLConst_h
#define XLConst_h

#import <UIKit/UIKit.h>

#endif /* XLConst_h */


/*!
 * 视频输入尺寸类型
 */
typedef NS_ENUM(NSUInteger, XLCaptureSessionPreset) {
    XLCaptureSessionPreset325x288,
    XLCaptureSessionPreset640x480, //默认
    XLCaptureSessionPreset1280x720,
    XLCaptureSessionPreset1920x1080,
    XLCaptureSessionPreset3840x2160,
};

/*!
 * 导出视频类型
 */
typedef NS_ENUM(NSUInteger, XLExportVideoType) {
    XLExportVideoTypeMov,       //默认
    XLExportVideoTypeMp4,
};


/*!
 * 尺寸
 */
extern CGFloat  const PhotoButtonLength;
extern CGFloat  const PhotoVerticalMargin;
extern CGFloat  const PhotoHorizontalMargin;
extern CGFloat  const PhotoInsideMargin;
extern CGFloat  const PhotoBackLength;


