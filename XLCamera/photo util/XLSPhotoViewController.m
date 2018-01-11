//
//  XLSCameraViewController.m
//  XLCamera
//
//  Created by Facebook on 2018/1/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "XLSPhotoViewController.h"
#import "XLSCameraManager.h"
#import "XLPhotoLibraryManager.h"
#import "XLConst.h"

@interface XLSPhotoViewController ()
/** 背景视图 */
@property (nonatomic, strong) UIView *backView;
/** 录制/暂停按钮 */
@property (nonatomic, strong) UIButton *inputButton;
/**  左侧 返回/重录 按钮, */
@property (nonatomic, strong) UIButton *leftButton;
/** 右侧 切换/确认 按钮 */
@property (nonatomic, strong) UIButton *rightButton;
/** 录制管理类 */
@property (nonatomic, strong) XLSCameraManager *manager;
@end

@implementation XLSPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.backView];
    self.manager = [[XLSCameraManager alloc] initWithSuperView:self.backView];
    [self.manager openVideo];
    [self.backView addSubview:self.inputButton];
    [self.backView addSubview:self.leftButton];
    [self.backView addSubview:self.rightButton];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.manager openVideo];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.manager closeVideo];
}



#pragma mark <Button点击事件>

-(void)dothings:(UIButton *)sender{
    switch (sender.tag-100) {
        case 0:
        {
            [self takePicture];
        }
            break;
        case 1:
        {
            if (!sender.selected) {            //返回方法
                [self dismissViewControllerAnimated:YES completion:nil];
            }else{                     //移除重拍方法
                [self cannel];
            }
        }
            break;
        case 2:
        {
            if (!sender.selected) {                    //切换摄像头
                [self.manager exchangeCamera];
            }else{         //确定
                if ([self.manager getOriginalImage]) {
                    [XLPhotoLibraryManager savePhotoWithImage:[self.manager getOriginalImage] andAssetCollectionName:nil withCompletion:^(UIImage *image, NSError *error) {
                        if (self.delegate&&[self.delegate respondsToSelector:@selector(photoCompleteWithPhoto:)]) {
                            [self.delegate photoCompleteWithPhoto:image];
                        }
                    }];
                }
            }
        }
            break;
            
        default:
            break;
    }
}
/**
 重拍
 */
- (void)cannel{
    [self.manager cannel];
    self.inputButton.hidden = false;
    self.leftButton.selected = false;
    self.rightButton.selected = false;
}

/**
 拍照
 */
- (void)takePicture{
    self.inputButton.hidden = true;
    [self.manager takePicture];
    self.leftButton.selected = true;
    self.rightButton.selected = true;
}

#pragma mark < 懒加载 >
-(UIView *)backView{
    if (!_backView) {
        _backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        _backView.backgroundColor = [UIColor blackColor];
    }
    return _backView;
}


-(UIButton *)inputButton{
    if (!_inputButton) {
        _inputButton = [[UIButton alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width - PhotoButtonLength)/2, [UIScreen mainScreen].bounds.size.height - PhotoButtonLength - PhotoButtonLength/2, PhotoButtonLength, PhotoButtonLength)];
        [_inputButton setBackgroundImage:[UIImage imageNamed:@"release_video_shooting"] forState:UIControlStateNormal];
        [_inputButton addTarget:self action:@selector(dothings:) forControlEvents:UIControlEventTouchUpInside];
        _inputButton.tag = 100;
    }
    return _inputButton;
}

-(UIButton *)leftButton{
    if (!_leftButton) {
        _leftButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.inputButton.frame) - PhotoBackLength - PhotoHorizontalMargin, CGRectGetMinY(self.inputButton.frame) + (CGRectGetHeight(self.inputButton.frame) - PhotoBackLength) / 2 , PhotoBackLength, PhotoBackLength)];
        [_leftButton setBackgroundImage:[UIImage imageNamed:@"release_video_down"] forState:UIControlStateNormal];
        [_leftButton setBackgroundImage:[UIImage imageNamed:@"release_video_return"] forState:UIControlStateSelected];
        [_leftButton setShowsTouchWhenHighlighted:false];
        [_leftButton setAdjustsImageWhenHighlighted:false];
        [_leftButton addTarget:self action:@selector(dothings:) forControlEvents:UIControlEventTouchUpInside];
        _leftButton.tag = 101;
    }
    return _leftButton;
}

-(UIButton *)rightButton{
    if (!_rightButton) {
        _rightButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.inputButton.frame) + PhotoHorizontalMargin, CGRectGetMinY(self.leftButton.frame), PhotoBackLength, PhotoBackLength)];
        [_rightButton setBackgroundImage:[UIImage imageNamed:@"release_video_switch"] forState:UIControlStateNormal];
        [_rightButton setBackgroundImage:[UIImage imageNamed:@"release_video_determine"] forState:UIControlStateSelected];
        [_rightButton addTarget:self action:@selector(dothings:) forControlEvents:UIControlEventTouchUpInside];
        [_rightButton setShowsTouchWhenHighlighted:false];
        [_rightButton setAdjustsImageWhenHighlighted:false];
        _rightButton.tag = 102;
    }
    return _rightButton;
}

@end

