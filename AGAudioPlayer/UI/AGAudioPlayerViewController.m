//
//  AGAudioPlayerViewController.m
//  AGAudioPlayer
//
//  Created by Alec Gorge on 3/13/15.
//  Copyright (c) 2015 Alec Gorge. All rights reserved.
//

#import "AGAudioPlayerViewController.h"

#import "AGAudioPlayer.h"

#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>

#import <ASValueTrackingSlider/ASValueTrackingSlider.h>

@interface AGAudioPlayerViewController () <ASValueTrackingSliderDataSource>

@property (nonatomic, weak) IBOutlet ASValueTrackingSlider *uiProgressSlider;
@property (weak, nonatomic) IBOutlet UIView *uiLoopHighlightView;
@property (weak, nonatomic) IBOutlet UIView *uiShuffleHighlightView;
@property (weak, nonatomic) IBOutlet UIButton *uiLoopButton;
@property (weak, nonatomic) IBOutlet UIButton *uiShuffleButton;
@property (weak, nonatomic) IBOutlet MPVolumeView *uiVolumeView;

@property (nonatomic) AGAudioPlayer *audioPlayer;

@end

@implementation AGAudioPlayerViewController

- (instancetype)init {
    if (self = [super initWithNibName:NSStringFromClass(AGAudioPlayerViewController.class)
                               bundle:nil]) {
        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithNibName:NSStringFromClass(AGAudioPlayerViewController.class)
                               bundle:nil]) {
        
    }
    return self;
}

- (void)roundCornersOfView:(UIView *)view
                  toRadius:(CGFloat)radius {
    view.layer.cornerRadius = radius;
    view.layer.masksToBounds = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupColorDefaults];

    [self roundCornersOfView:self.uiLoopHighlightView
                    toRadius:2];
    [self roundCornersOfView:self.uiShuffleHighlightView
                    toRadius:2];
    
    self.uiProgressSlider.dataSource = self;
    self.uiProgressSlider.popUpViewCornerRadius = 2.0f;
    self.uiProgressSlider.popUpViewColor = self.darkForegroundColor;
    self.uiProgressSlider.textColor = self.lightForegroundColor;
    
    for (id current in self.uiVolumeView.subviews) {
        if ([current isKindOfClass:[UISlider class]]) {
            UISlider *volumeSlider = (UISlider *)current;
            volumeSlider.minimumTrackTintColor = self.lightForegroundColor;
            volumeSlider.maximumTrackTintColor = self.darkForegroundColor;
        }
    }
}

- (void)setupColorDefaults {
    if(self.foregroundColor == nil) {
        self.foregroundColor = UIColor.whiteColor;
    }
    
    if(self.backgroundColor == nil) {
        self.backgroundColor = UIColor.blackColor;
    }
    
    if(self.lightForegroundColor == nil) {
        self.lightForegroundColor = UIColor.lightGrayColor;
    }
    
    if(self.darkForegroundColor == nil) {
        self.darkForegroundColor = UIColor.darkGrayColor;
    }
    
    self.view.backgroundColor = self.backgroundColor;
}

- (void)redrawUI {

}

- (NSString *)slider:(ASValueTrackingSlider *)slider stringForValue:(float)value {
    return @"00:00";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
