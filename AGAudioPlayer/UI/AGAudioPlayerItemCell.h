//
//  AGAudioPlayerItemCell.h
//  AGAudioPlayer
//
//  Created by Alec Gorge on 3/15/15.
//  Copyright (c) 2015 Alec Gorge. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AGAudioItem.h"

@class NAKPlaybackIndicatorView, LLACircularProgressView;

@interface AGAudioPlayerItemCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *uiLeftAccessoryView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *uiLeftAccessoryWidthConstraint;

@property (weak, nonatomic) IBOutlet NAKPlaybackIndicatorView *uiPlaybackIndicatorView;
@property (weak, nonatomic) IBOutlet UILabel *uiTrackNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *uiTitleLabel;
@property (weak, nonatomic) IBOutlet LLACircularProgressView *uiDownloadProgressView;
@property (weak, nonatomic) IBOutlet UIButton *uiDownloadButton;
@property (weak, nonatomic) IBOutlet UILabel *uiDurationLabel;

- (void)updateCellWithAudioItem:(id<AGAudioItem>)item;

@end
