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
#import "XLCameraToolView.h"
#import "XLPlayer.h"
#import "XLFileManager.h"
#import "XLPhotoLibraryManager.h"

@interface XLCameraViewController ()<CameraToolViewDelegate, AVCaptureFileOutputRecordingDelegate>
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
@property (nonatomic, strong) XLCameraToolView *toolView;                //底部视图
@end

@implementation XLCameraViewController
{
    BOOL _dragStart;    //拖拽手势开始的录制
    BOOL _layoutOK;
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = YES;
    [self.session startRunning];
    [self setFocusCursorWithPoint:self.view.center];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [UIApplication sharedApplication].statusBarHidden = NO;
    if (self.session) {
        [self.session stopRunning];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupCamera];
    [self observeDeviceMotion];
    
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                if (!granted) {
                    [self onDismiss];
                } else {
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
                }
            }];
        } else {
            [self onDismiss];
        }
    }];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];     //暂停其他音乐，
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    if (self.allowRecordVideo) {                ///添加录制手势
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(adjustCameraFocus:)];
        [self.view addGestureRecognizer:pan];
    }
    
    [self performSelector:@selector(hiddenTips) withObject:nil afterDelay:4];           ///延迟4秒隐藏提示文字
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    if (_layoutOK) return;
    _layoutOK = YES;
    self.toolView.frame = CGRectMake(0, kViewHeight-130-ZL_SafeAreaBottom, kViewWidth, PhotoToolViewVerticalLength);
    self.tipsLabel.frame =CGRectMake(PhotoHorizontalMargin,CGRectGetMinY(self.toolView.frame)-PhotoInsideMargin-PhotoHorizontalMargin,self.view.frame.size.width - PhotoHorizontalMargin * 2, PhotoHorizontalMargin);
    self.toggleCameraBtn.frame = CGRectMake(self.view.frame.size.width - PhotoInsideMargin*3/2-PhotoBackLength, PhotoInsideMargin*2, PhotoBackLength, PhotoBackLength);
    self.previewLayer.frame = self.view.layer.bounds;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.motionManager stopDeviceMotionUpdates];
    self.motionManager = nil;
}

/*!
 * 视频输出输入配置
 */
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

#pragma mark < AVCaptureFileOutputRecordingDelegate >
- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections{
    [self.toolView startAnimate];
}

- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error{
    if (CMTimeGetSeconds(output.recordedDuration) < 1) {      //视频长度小于1s 则拍照
        [self onTakePicture];
        return;
    }
    self.videoUrl = outputFileURL;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self playVideo];
    });
}

#pragma mark <视频输出配置>
/*!
 * 监控运动方向
 */
- (void)observeDeviceMotion{
    self.motionManager = [[CMMotionManager alloc] init];     // 提供设备运动数据到指定的时间间隔
    self.motionManager.deviceMotionUpdateInterval = .5;
    
    if (self.motionManager.deviceMotionAvailable) {  // 确定是否使用任何可用的态度参考帧来决定设备的运动是否可用
        // 启动设备的运动更新，通过给定的队列向给定的处理程序提供数据。
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
            [self performSelectorOnMainThread:@selector(handleDeviceMotion:) withObject:motion waitUntilDone:YES];
        }];
    } else {
        self.motionManager = nil;
    }
}
/*!
 * 监控运动方向坐标判断方向
 */
- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion{
    double x = deviceMotion.gravity.x;
    double y = deviceMotion.gravity.y;
    if (fabs(y) >= fabs(x)) {
        if (y >= 0){
            // UIDeviceOrientationPortraitUpsideDown;
            self.orientation = AVCaptureVideoOrientationPortraitUpsideDown;
        } else {
            // UIDeviceOrientationPortrait;
            self.orientation = AVCaptureVideoOrientationPortrait;
        }
    } else {
        if (x >= 0) {
            //视频拍照转向，左右和屏幕转向相反
            // UIDeviceOrientationLandscapeRight;
            self.orientation = AVCaptureVideoOrientationLandscapeLeft;
        } else {
            // UIDeviceOrientationLandscapeLeft;
            self.orientation = AVCaptureVideoOrientationLandscapeRight;
        }
    }
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

/*!
 * 设置聚焦点位置
 */
- (void)setFocusCursorWithPoint:(CGPoint)point{
    self.focusCursorImageView.center = point;
    self.focusCursorImageView.alpha = 1;
    self.focusCursorImageView.transform = CGAffineTransformMakeScale(1.1, 1.1);
    [UIView animateWithDuration:0.5 animations:^{
        self.focusCursorImageView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursorImageView.alpha=0;
    }];
    CGPoint cameraPoint = [self.previewLayer captureDevicePointOfInterestForPoint:point];     //将UI坐标转化为摄像头坐标
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}

/*!
 * 设置聚焦点
 */
- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    AVCaptureDevice * captureDevice = [self.videoInput device];
    NSError * error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if (![captureDevice lockForConfiguration:&error]) {
        return;
    }
    //聚焦模式
    if ([captureDevice isFocusModeSupported:focusMode]) {
        [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
    }
    //聚焦点
    if ([captureDevice isFocusPointOfInterestSupported]) {
        [captureDevice setFocusPointOfInterest:point];
    }
    //    //曝光模式
    //    if ([captureDevice isExposureModeSupported:exposureMode]) {
    //        [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
    //    }
    //    //曝光点
    //    if ([captureDevice isExposurePointOfInterestSupported]) {
    //        [captureDevice setExposurePointOfInterest:point];
    //    }
    [captureDevice unlockForConfiguration];
}

/*!
 * 点击屏幕设置聚焦点
 */
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (!self.session.isRunning) return;
    CGPoint point = [touches.anyObject locationInView:self.view];
    if (point.y > [UIScreen mainScreen].bounds.size.height-150-ZL_SafeAreaBottom) {
        return;
    }
    [self setFocusCursorWithPoint:point];
}

#pragma mark  < Button事件 >

/*!
 *  注册通知
 */
- (void)willResignActive{
    if ([self.session isRunning]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

/*!
 * 调节焦距
 */
- (void)adjustCameraFocus:(UIPanGestureRecognizer *)pan{
    CGRect caremaViewRect = [self.toolView convertRect:self.toolView.bottomView.frame toView:self.view];
    CGPoint point = [pan locationInView:self.view];
    if (pan.state == UIGestureRecognizerStateBegan) {
        if (!CGRectContainsPoint(caremaViewRect, point)) {
            return;
        }
        _dragStart = YES;
        [self onStartRecord];
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        if (!_dragStart) return;
        
        CGFloat zoomFactor = (CGRectGetMidY(caremaViewRect)-point.y)/CGRectGetMidY(caremaViewRect) * 10;
        [self setVideoZoomFactor:MIN(MAX(zoomFactor, 1), 10)];
    } else if (pan.state == UIGestureRecognizerStateCancelled ||
               pan.state == UIGestureRecognizerStateEnded) {
        if (!_dragStart) return;
        
        _dragStart = NO;
        [self onFinishRecord];         //这里需要结束动画
        [self.toolView stopAnimate];
    }
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

#pragma mark < CameraToolViewDelegate >

/*!
 单击事件，拍照
 */
- (void)onTakePicture{
    AVCaptureConnection * videoConnection = [self.imageOutPut connectionWithMediaType:AVMediaTypeVideo];
    videoConnection.videoOrientation = self.orientation;
    if (!videoConnection) {
        return;
    }
    if (!_takedImageView) {
        _takedImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _takedImageView.backgroundColor = [UIColor blackColor];
        _takedImageView.hidden = YES;
        _takedImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.view insertSubview:_takedImageView belowSubview:self.toolView];
    }
    __weak typeof(self) weakSelf = self;
    [self.imageOutPut captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer == NULL) {
            return;
        }
        NSData * imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage * image = [UIImage imageWithData:imageData];
        weakSelf.takedImage = image;
        weakSelf.takedImageView.hidden = NO;
        weakSelf.takedImageView.image = image;
        [weakSelf.session stopRunning];
    }];
}
/*!
 开始录制
 */
- (void)onStartRecord{
    AVCaptureConnection *movieConnection = [self.movieFileOutPut connectionWithMediaType:AVMediaTypeVideo];
    movieConnection.videoOrientation = self.orientation;
    [movieConnection setVideoScaleAndCropFactor:1.0];
    if (![self.movieFileOutPut isRecording]) {
        NSURL *url = [NSURL fileURLWithPath:[self getVideoExportFilePath:self.videoType]];
        [self.movieFileOutPut startRecordingToOutputFileURL:url recordingDelegate:self];
    }
}

/*!
 获取视频文件地址
 */
-(NSString *)getVideoExportFilePath:(XLExportVideoType)type{
    NSString *format = (type == XLExportVideoTypeMov ? @"mov" : @"mp4");
    NSString *exportFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",[[XLFileManager defaultManager]getUniqueStrByUUID], format]];
    return exportFilePath;
}

/*!
 结束录制
 */
- (void)onFinishRecord{
    [self.movieFileOutPut stopRecording];
    [self.session stopRunning];
    [self setVideoZoomFactor:1];
}
/*!
 重新拍照或录制
 */
- (void)onRetake{
    [self.session startRunning];
    [self setFocusCursorWithPoint:self.view.center];
    self.takedImageView.hidden = YES;
    [self deleteVideo];
}
/*!
 点击确定
 */
- (void)onOkClick{
    [self.playerView reset];
    
    //保存视频，保存图片
    if (self.takedImage) {
        [XLPhotoLibraryManager savePhotoWithImage:self.takedImage andAssetCollectionName:nil withCompletion:^(UIImage *image, NSError *error) {
            NSLog(@"image:%@ = error:%@",image,error);
        }];
    }
    if (self.videoUrl) {
        [XLPhotoLibraryManager saveVideoWithVideoUrl:self.videoUrl andAssetCollectionName:nil withCompletion:^(NSURL *vedioUrl, NSError *error) {
            NSLog(@"vedioUrl:%@ = error:%@",vedioUrl,error);
        }];
    }
    
    if (self.doneCompletBlock) {
        self.doneCompletBlock(self.takedImage, self.videoUrl);
    }
    
    [self onDismiss];
}
/*!
 点击取消
 */
- (void)onDismiss{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

/*!
 删除视频
 */
- (void)deleteVideo{
    if (self.videoUrl) {
        [self.playerView reset];
        self.playerView.alpha = 0;
        [[NSFileManager defaultManager] removeItemAtURL:self.videoUrl error:nil];
    }
}

/*!
 播放录制视频
 */
- (void)playVideo{
    if (!_playerView) {
        self.playerView = [[XLPlayer alloc] initWithFrame:self.view.bounds];
        [self.view insertSubview:self.playerView belowSubview:self.toolView];
    }
    self.playerView.videoUrl = self.videoUrl;
    [self.playerView play];
}

#pragma mark < 懒加载控件 >
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
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.textColor = [UIColor whiteColor];
        _tipsLabel.font = [UIFont systemFontOfSize:13.0];
        _tipsLabel.text = @"轻触拍照，按住摄像";
        [self.view addSubview:_tipsLabel];
    }
    return _tipsLabel;
}

-(XLCameraToolView *)toolView{
    if (!_toolView) {
        _toolView = [[XLCameraToolView alloc] init];
        _toolView.delegate = self;
        _toolView.allowRecordVideo = self.allowRecordVideo;
        _toolView.circleProgressColor = self.circleProgressColor;
        _toolView.maxRecordDuration = self.maxRecordDuration;
        [self.view addSubview:_toolView];
    }
    return _toolView;
}


#pragma mark < dealloc >
- (void)dealloc{
    if ([_session isRunning]) {
        [_session stopRunning];
    }
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"dealloc:%s", __FUNCTION__);
}
@end

