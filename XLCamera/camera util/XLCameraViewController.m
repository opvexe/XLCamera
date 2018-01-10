//
//  XLCameraViewController.m
//  XLCamera
//
//  Created by Facebook on 2018/1/10.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "XLCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import "XLPlayer.h"

@interface XLCameraViewController ()
@property (nonatomic, strong) AVCaptureSession *session;                 //AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;          //AVCaptureDeviceInput对象是输入流
@property (nonatomic, strong) AVCaptureStillImageOutput *imageOutPut;    //照片输出流对象
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutPut; //视频输出流
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;  //预览图层，显示相机拍摄到的画面
@property (nonatomic, strong) UIButton *toggleCameraBtn;                 //切换摄像头按钮
@property (nonatomic, strong) UIImageView *focusCursorImageView;         //聚焦图
@property (nonatomic, strong) UILabel *tipsLabel;                        //提示框
@property (nonatomic, strong) NSURL *videoUrl;                           //录制视频保存的url
@property (nonatomic, strong) UIImageView *takedImageView;               //拍照照片显示
@property (nonatomic, strong) UIImage *takedImage;                       //拍照的照片
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) AVCaptureVideoOrientation orientation;
@property (nonatomic, strong) XLPlayer *playerView;                      //播放视频
@end

@implementation XLCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupCamera];
    
    if (self.allowRecordVideo) {
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(adjustCameraFocus:)];
        [self.view addGestureRecognizer:pan];
    }
    
    [self performSelector:@selector(hiddenTips) withObject:nil afterDelay:4];
}



- (void)setupCamera{
    self.session = [[AVCaptureSession alloc] init];
    
    //相机画面输入流
    self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:[self backCamera] error:nil];
    
    //照片输出流
    self.imageOutPut = [[AVCaptureStillImageOutput alloc] init];
    //这是输出流的设置参数AVVideoCodecJPEG参数表示以JPEG的图片格式输出图片
    NSDictionary *dicOutputSetting = [NSDictionary dictionaryWithObject:AVVideoCodecJPEG forKey:AVVideoCodecKey];
    [self.imageOutPut setOutputSettings:dicOutputSetting];
    
    //音频输入流
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio].firstObject;
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:nil];
    
    //视频输出流
    //设置视频格式
    NSString *preset = [self transformSessionPreset];
    if ([self.session canSetSessionPreset:preset]) {
        self.session.sessionPreset = preset;
    } else {
        self.session.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    
    self.movieFileOutPut = [[AVCaptureMovieFileOutput alloc] init];
    
    //将视频及音频输入流添加到session
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddInput:audioInput]) {
        [self.session addInput:audioInput];
    }
    //将输出流添加到session
    if ([self.session canAddOutput:self.imageOutPut]) {
        [self.session addOutput:self.imageOutPut];
    }
    if ([self.session canAddOutput:self.movieFileOutPut]) {
        [self.session addOutput:self.movieFileOutPut];
    }
    //预览层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.view.layer setMasksToBounds:YES];
    
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
}

/*!
 * 视频输出配置
 */
- (NSString *)transformSessionPreset{
    switch (self.sessionPreset) {
        case XLCaptureSessionPreset325x288:
            return AVCaptureSessionPreset352x288;
            
        case XLCaptureSessionPreset640x480:
            return AVCaptureSessionPreset640x480;
            
        case XLCaptureSessionPreset1280x720:
            return AVCaptureSessionPreset1280x720;
            
        case XLCaptureSessionPreset1920x1080:
            return AVCaptureSessionPreset1920x1080;
            
        case XLCaptureSessionPreset3840x2160:
            return AVCaptureSessionPreset3840x2160;
    }
}

/*!
 * 设置摄像头后置
 */
- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

/*!
 * 设置摄像头前置
 */
- (AVCaptureDevice *)frontCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

/*!
 * 获取摄像头前后置
 */
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

/*!
 * 设置缩放比例
 */
- (void)setVideoZoomFactor:(CGFloat)zoomFactor{
    AVCaptureDevice * captureDevice = [self.videoInput device];
    NSError *error = nil;
    [captureDevice lockForConfiguration:&error];
    if (error) return;
    captureDevice.videoZoomFactor = zoomFactor;
    [captureDevice unlockForConfiguration];
}


#pragma mark  < Button事件 >
/*!
 * 调节焦距
 */
-(void)adjustCameraFocus:(UIPanGestureRecognizer *)tap{
    
}

/*!
 * 摄像头切换
 */
- (void)btnToggleCameraAction{
    NSUInteger cameraCount = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count;
    if (cameraCount > 1) {
        NSError *error;
        AVCaptureDeviceInput *newVideoInput;
        AVCaptureDevicePosition position = self.videoInput.device.position;
        if (position == AVCaptureDevicePositionBack) {
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
        } else if (position == AVCaptureDevicePositionFront) {
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
        } else {
            return;
        }
        if (newVideoInput) {
            [self.session beginConfiguration];
            [self.session removeInput:self.videoInput];
            if ([self.session canAddInput:newVideoInput]) {
                [self.session addInput:newVideoInput];
                self.videoInput = newVideoInput;
            } else {
                [self.session addInput:self.videoInput];
            }
            [self.session commitConfiguration];
        } else if (error) {
            NSLog(@"切换前后摄像头失败");
        }
    }
}
/*!
 * 隐藏提示
 */
-(void)hiddenTips{
    self.tipsLabel.hidden = YES;
}

/*!
 * 懒加载控件
 */
-(UIImageView *)focusCursorImageView{
    if (!_focusCursorImageView) {
        _focusCursorImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"focus"]];
        _focusCursorImageView.contentMode = UIViewContentModeScaleAspectFit;
        _focusCursorImageView.clipsToBounds = YES;
        _focusCursorImageView.frame = CGRectMake(0, 0, 80, 80);
        _focusCursorImageView.alpha = 0;
        [self.view addSubview:_focusCursorImageView];
    }
    return _focusCursorImageView;
}

-(UIButton *)toggleCameraBtn{
    if (!_toggleCameraBtn) {
        _toggleCameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_toggleCameraBtn setImage:[UIImage imageNamed:@"toggle_camera"] forState:UIControlStateNormal];
        [_toggleCameraBtn addTarget:self action:@selector(btnToggleCameraAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_toggleCameraBtn];
    }
    return _toggleCameraBtn;
}

-(UILabel *)tipsLabel{
    if (!_tipsLabel) {
        _tipsLabel = [[UILabel alloc]init];
        _tipsLabel.frame = CGRectMake(self.view.frame.size.width - PhotoInsideMargin*3/2-PhotoBackLength, PhotoInsideMargin*2, PhotoBackLength, PhotoBackLength);
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.textColor = [UIColor whiteColor];
        _tipsLabel.font = [UIFont systemFontOfSize:13.0];
        _tipsLabel.text = @"轻触拍照，按住摄像";
        [self.view addSubview:_tipsLabel];
    }
    return _tipsLabel;
}

- (void)dealloc{
    if ([_session isRunning]) {
        [_session stopRunning];
    }
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"dealloc:%s", __FUNCTION__);
}
@end

