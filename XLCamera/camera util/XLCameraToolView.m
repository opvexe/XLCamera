//
//  XLCameraToolView.m
//  XLCamera
//
//  Created by Facebook on 2018/1/10.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "XLCameraToolView.h"


#define kTopViewScale .5
#define kBottomViewScale .7
#define kAnimateDuration .1
#define kRGB(r, g, b)   [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]

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







/*!
 * Button点击
 */

-(void)dothings:(UIButton *)sender{
    
    switch (sender.tag -100) {
        case 1:
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(onDismiss)]) {
                [self.delegate performSelector:@selector(onDismiss)];
            }
        }
            break;
            
        case 2:
        {
//            [self resetUI];
            if (self.delegate && [self.delegate respondsToSelector:@selector(onRetake)]) {
                [self.delegate performSelector:@selector(onRetake)];
            }
        }
            break;
        case 3:
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


#pragma mark   < GestureRecognizer >


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
        _bottomView.backgroundColor = [kRGB(244, 244, 244) colorWithAlphaComponent:.9];
        [self addSubview:_bottomView];
        [_bottomView addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)]];
    }
    return _bottomView;
}

-(UIView *)topView{
    if (!_topView) {
        _topView = [[UIView alloc]init];
        _topView.layer.masksToBounds = YES;
        _topView.backgroundColor = [UIColor whiteColor];
        _topView.userInteractionEnabled = YES;
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

