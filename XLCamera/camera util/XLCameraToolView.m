//
//  XLCameraToolView.m
//  XLCamera
//
//  Created by Facebook on 2018/1/10.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "XLCameraToolView.h"
#import <Foundation/Foundation.h>
#import "XLConst.h"

#define kTopViewScale .5
#define kBottomViewScale .7

@interface XLCameraToolView()<CAAnimationDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIButton *dismissBtn;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *doneBtn;
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) CAShapeLayer *animateLayer;
@property (nonatomic, assign) CGFloat duration;
@end

@implementation XLCameraToolView
{
    BOOL _stopRecord;
    BOOL _layoutOK;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}


- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}


-(void)layoutSubviews{
    [super layoutSubviews];
    if (_layoutOK) return;
    
    _layoutOK = YES;
    CGFloat height = self.frame.size.height;
    self.bottomView.frame = CGRectMake(0, 0, height*kBottomViewScale, height*kBottomViewScale);
    self.bottomView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.bottomView.layer.cornerRadius = height*kBottomViewScale/2;
    
    self.topView.frame = CGRectMake(0, 0, height*kTopViewScale, height*kTopViewScale);
    self.topView.center = self.bottomView.center;
    self.topView.layer.cornerRadius = height*kTopViewScale/2;
    
    self.dismissBtn.frame = CGRectMake(60, self.bounds.size.height/2-25/2, 25, 25);
    
    self.cancelBtn.frame = self.bottomView.frame;
    self.cancelBtn.layer.cornerRadius = height*kBottomViewScale/2;
    
    self.doneBtn.frame = self.bottomView.frame;
    self.doneBtn.layer.cornerRadius = height*kBottomViewScale/2;
}

/*!
 * Button点击
 */

-(void)dothings:(UIButton *)sender{
    
    switch (sender.tag -100) {
        case 1:         ///取消
        {
            [self resetUI];
            if (self.delegate && [self.delegate respondsToSelector:@selector(onRetake)]) {
                [self.delegate performSelector:@selector(onRetake)];
            }
        }
            break;
            
        case 2:
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(onDismiss)]) {
                [self.delegate performSelector:@selector(onDismiss)];
            }
        }
            break;
        case 3:             ///确定
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(onOkClick)]) {
                [self.delegate performSelector:@selector(onOkClick)];
            }
        }
            break;
            
        default:
            break;
    }
}

/*!
 * <Set>方法
 */
- (void)setAllowRecordVideo:(BOOL)allowRecordVideo{
    _allowRecordVideo = allowRecordVideo;
    if (allowRecordVideo) {
        UILongPressGestureRecognizer *longG = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        longG.minimumPressDuration = .3;
        longG.delegate = self;
        [self.bottomView addGestureRecognizer:longG];
    }
}
#pragma mark   < GestureRecognizer >
/*!
 * 点击手势
 */
- (void)tapAction:(UITapGestureRecognizer *)tap{
    [self stopAnimate];
    if (self.delegate && [self.delegate respondsToSelector:@selector(onTakePicture)]) {
        [self.delegate performSelector:@selector(onTakePicture)];
    }
}

/*!
 * 长按手势
 */
- (void)longPressAction:(UILongPressGestureRecognizer *)longG{
    switch (longG.state) {
        case UIGestureRecognizerStateBegan:
        {  //此处不启动动画，由vc界面开始录制之后启动
            _stopRecord = NO;
            if (self.delegate && [self.delegate respondsToSelector:@selector(onStartRecord)]) {
                [self.delegate performSelector:@selector(onStartRecord)];
            }
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        {
            if (_stopRecord) return;
            _stopRecord = YES;
            [self stopAnimate];
            if (self.delegate && [self.delegate respondsToSelector:@selector(onFinishRecord)]) {
                [self.delegate performSelector:@selector(onFinishRecord)];
            }
        }
            break;
            
        default:
            break;
    }
}

#pragma mark < UIGestureRecognizerDelegate >
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer{
    if (([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])) {
        return YES;
    }
    return NO;
}


#pragma mark  <私有方法>
/*!
 * 开始动画
 */
- (void)startAnimate{
    self.dismissBtn.hidden = YES;
    [UIView animateWithDuration:0.25 animations:^{
        self.bottomView.layer.transform = CATransform3DScale(CATransform3DIdentity, 1/kBottomViewScale, 1/kBottomViewScale, 1);
        self.topView.layer.transform = CATransform3DScale(CATransform3DIdentity, 0.7, 0.7, 1);
    } completion:^(BOOL finished) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        animation.fromValue = @(0);
        animation.toValue = @(1);
        animation.duration = self.maxRecordDuration;
        animation.delegate = self;
        [self.animateLayer addAnimation:animation forKey:nil];
        [self.bottomView.layer addSublayer:self.animateLayer];
    }];
}
/*!
 * 结束动画
 */
- (void)stopAnimate{
    if (_animateLayer) {
        [self.animateLayer removeFromSuperlayer];
        [self.animateLayer removeAllAnimations];
    }
    
    self.bottomView.hidden = YES;
    self.topView.hidden = YES;
    self.dismissBtn.hidden = YES;
    self.bottomView.layer.transform = CATransform3DIdentity;
    self.topView.layer.transform = CATransform3DIdentity;
    [self showCancelDoneBtn];
}
/*!
 * 动画停止
 */
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    if (_stopRecord) return;
    _stopRecord = YES;
    [self stopAnimate];
    if (self.delegate && [self.delegate respondsToSelector:@selector(onFinishRecord)]) {
        [self.delegate performSelector:@selector(onFinishRecord)];
    }
}

/*!
 * 展示确定取消按钮
 */
- (void)showCancelDoneBtn{
    self.cancelBtn.hidden = NO;
    self.doneBtn.hidden = NO;
    CGRect cancelRect = self.cancelBtn.frame;
    cancelRect.origin.x = 40;
    CGRect doneRect = self.doneBtn.frame;
    doneRect.origin.x = self.frame.size.width-doneRect.size.width-40;
    [UIView animateWithDuration:0.25 animations:^{
        self.cancelBtn.frame = cancelRect;
        self.doneBtn.frame = doneRect;
    }];
}

/*!
 * 重置视图
 */
- (void)resetUI{
    if (_animateLayer.superlayer) {
        [self.animateLayer removeAllAnimations];
        [self.animateLayer removeFromSuperlayer];
    }
    self.dismissBtn.hidden = NO;
    self.bottomView.hidden = NO;
    self.topView.hidden = NO;
    self.cancelBtn.hidden = YES;
    self.doneBtn.hidden = YES;
    
    self.cancelBtn.frame = self.bottomView.frame;
    self.doneBtn.frame = self.bottomView.frame;
}

#pragma mark <懒加载控件>
/*!
 * 懒加载控件
 */
- (CAShapeLayer *)animateLayer{
    if (!_animateLayer) {
        _animateLayer = [CAShapeLayer layer];
        CGFloat width = CGRectGetHeight(self.bottomView.frame)*kBottomViewScale;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, width, width) cornerRadius:width/2];
        _animateLayer.strokeColor = self.circleProgressColor.CGColor;
        _animateLayer.fillColor = [UIColor clearColor].CGColor;
        _animateLayer.path = path.CGPath;
        _animateLayer.lineWidth = 8;
    }
    return _animateLayer;
}

-(UIView *)bottomView{
    if (!_bottomView) {
        _bottomView = [[UIView alloc]init];
        _bottomView.layer.masksToBounds = YES;
        _bottomView.userInteractionEnabled = YES;
        _bottomView.backgroundColor = [kRGB(244, 244, 244) colorWithAlphaComponent:.9];
        [self addSubview:_bottomView];
        [_bottomView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)]];
    }
    return _bottomView;
}

-(UIView *)topView{
    if (!_topView) {
        _topView = [[UIView alloc]init];
        _topView.layer.masksToBounds = YES;
        _topView.backgroundColor = [UIColor redColor];
        _topView.userInteractionEnabled = NO;
        [self addSubview:_topView];
    }
    return _topView;
}

-(UIButton *)cancelBtn{
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelBtn.backgroundColor = [kRGB(244, 244, 244) colorWithAlphaComponent:.9];
        [_cancelBtn setImage:[UIImage imageNamed:@"retake"] forState:UIControlStateNormal];
        [_cancelBtn addTarget:self action:@selector(dothings:) forControlEvents:UIControlEventTouchUpInside];
        _cancelBtn.layer.masksToBounds = YES;
        _cancelBtn.hidden = YES;
        _cancelBtn.tag = 101;
        [self addSubview:_cancelBtn];
    }
    return _cancelBtn;
}

-(UIButton *)dismissBtn{
    if (!_dismissBtn) {
        _dismissBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _dismissBtn.frame = CGRectMake(60, self.bounds.size.height/2-25/2, 25, 25);
        [_dismissBtn setImage:[UIImage imageNamed:@"arrow_down"] forState:UIControlStateNormal];
        [_dismissBtn addTarget:self action:@selector(dothings:) forControlEvents:UIControlEventTouchUpInside];
        _dismissBtn.tag = 102;
        [self addSubview:_dismissBtn];
    }
    return _dismissBtn;
}

-(UIButton *)doneBtn{
    if (!_doneBtn) {
        _doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _doneBtn.frame = self.bottomView.frame;
        _doneBtn.backgroundColor = [UIColor whiteColor];
        [_doneBtn setImage:[UIImage imageNamed:@"takeok"] forState:UIControlStateNormal];
        [_doneBtn addTarget:self action:@selector(dothings:) forControlEvents:UIControlEventTouchUpInside];
        _doneBtn.layer.masksToBounds = YES;
        _doneBtn.hidden = YES;
        _doneBtn.tag = 103;
        [self addSubview:_doneBtn];
    }
    return _doneBtn;
}

@end

