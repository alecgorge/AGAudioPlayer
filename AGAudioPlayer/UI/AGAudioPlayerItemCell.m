//
//  AGAudioPlayerItemCell.m
//  AGAudioPlayer
//
//  Created by Alec Gorge on 3/15/15.
//  Copyright (c) 2015 Alec Gorge. All rights reserved.
//

#import "AGAudioPlayerItemCell.h"

#import "AGAudioItem.h"
#import "AGDurationHelper.h"

#import <NAKPlaybackIndicatorView/NAKPlaybackIndicatorView.h>
#import <LLACircularProgressView/LLACircularProgressView.h>

@implementation AGAudioPlayerItemCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)updateCellWithAudioItem:(id<AGAudioItem>)item {
	self.uiTrackNumberLabel.text = @(item.trackNumber).stringValue;
	self.uiTitleLabel.text = item.displayText;
	self.uiDurationLabel.text = [AGDurationHelper formattedTimeWithInterval:item.duration];
}

@end
