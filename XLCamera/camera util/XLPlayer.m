//
//  XLPlayer.m
//  XLCamera
//
//  Created by Facebook on 2018/1/10.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "XLPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface XLPlayer ()
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayer *player;
@end
@implementation XLPlayer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        self.alpha = 0;
        self.playerLayer = [[AVPlayerLayer alloc] init];
        self.playerLayer.frame = self.bounds;
        [self.layer addSublayer:self.playerLayer];
    }
    return self;
}

- (void)setVideoUrl:(NSURL *)videoUrl{
    _player = [AVPlayer playerWithURL:videoUrl];
    _player.automaticallyWaitsToMinimizeStalling = NO;
    [_player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinished) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    self.playerLayer.player = _player;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        if (_player.status == AVPlayerStatusReadyToPlay) {
            [UIView animateWithDuration:0.25 animations:^{
                self.alpha = 1;
            }];
        }
    }
}

- (void)playFinished{
    [_player seekToTime:kCMTimeZero];
    [_player play];
}

- (void)play{
    [_player play];
}

- (void)pause{
    [_player pause];
}

- (void)reset{
    [self removeObserver];
    [_player pause];
    _player = nil;
}

- (BOOL)isPlay{
    return _player && _player.rate > 0;
}

- (void)removeObserver{
    [_player removeObserver:self forKeyPath:@"status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc{
    [self removeObserver];
    [_player pause];
    _player = nil;
    NSLog(@"dealloc:%s", __FUNCTION__);
}
@end

