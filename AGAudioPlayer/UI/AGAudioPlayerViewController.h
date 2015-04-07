//
//  AGAudioPlayerViewController.h
//  AGAudioPlayer
//
//  Created by Alec Gorge on 3/13/15.
//  Copyright (c) 2015 Alec Gorge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AGAudioPlayer;

@interface AGAudioPlayerViewController : UIViewController

@property (nonatomic) UIColor *backgroundColor;
@property (nonatomic) UIColor *foregroundColor;
@property (nonatomic) UIColor *foregroundHighlightColor;
@property (nonatomic) UIColor *lightForegroundColor;
@property (nonatomic) UIColor *darkForegroundColor;

- (instancetype)initWithAudioPlayer:(AGAudioPlayer *)audioPlayer;

@property (nonatomic) AGAudioPlayer *audioPlayer;
@property (nonatomic) UIColor *tintColor;

@end
