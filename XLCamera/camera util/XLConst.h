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

#define kRGB(r, g, b)   [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]
#define kViewWidth      [[UIScreen mainScreen] bounds].size.width
#define kViewHeight     [[UIScreen mainScreen] bounds].size.height
#define ZL_IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define ZL_IS_IPHONE_X (ZL_IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 812.0f)
#define ZL_SafeAreaBottom (ZL_IS_IPHONE_X ? 34 : 0)

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
extern CGFloat  const PhotoToolViewVerticalLength;

