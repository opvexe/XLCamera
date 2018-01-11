//
//  XLSCameraViewController.h
//  XLCamera
//
//  Created by Facebook on 2018/1/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CameraViewControllerDelegate <NSObject>

- (void)photoCompleteWithPhoto:(UIImage *)photo;

@end

/**
 * 自定义相机
 */
@interface XLSPhotoViewController : UIViewController

@property (nonatomic, weak) id<CameraViewControllerDelegate> delegate;

@end
