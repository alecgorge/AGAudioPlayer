//
//  AGAudioPlayerViewController.m
//  AGAudioPlayer
//
//  Created by Alec Gorge on 3/13/15.
//  Copyright (c) 2015 Alec Gorge. All rights reserved.
//

#import "AGAudioPlayerViewController.h"

#import "AGAudioPlayer.h"
#import "AGDurationHelper.h"
#import "AGScrubber.h"
#import "AGAudioPlayerItemCell.h"

#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import <MarqueeLabel/MarqueeLabel.h>

#import <ASValueTrackingSlider/ASValueTrackingSlider.h>

@interface AGAudioPlayerViewController () <ASValueTrackingSliderDataSource, AGAudioPlayerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *uiQueueTable;
@property (weak, nonatomic) IBOutlet UIImageView *uiAlbumArtImage;

@property (nonatomic, weak) IBOutlet ASValueTrackingSlider *uiProgressSlider;

@property (weak, nonatomic) IBOutlet UILabel *uiTimeElapsedLabel;
@property (weak, nonatomic) IBOutlet UILabel *uiTimeRemainingLabel;

@property (weak, nonatomic) IBOutlet MarqueeLabel *uiTitleLabel;
@property (weak, nonatomic) IBOutlet MarqueeLabel *uiSubtitleLabel;

@property (weak, nonatomic) IBOutlet MPVolumeView *uiVolumeView;

@property (weak, nonatomic) IBOutlet UIButton *uiBackwardButton;
@property (weak, nonatomic) IBOutlet UIButton *uiForwardButton;
@property (weak, nonatomic) IBOutlet UIButton *uiPlayButton;
@property (weak, nonatomic) IBOutlet UIButton *uiPauseButton;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *uiToolbarRepeat;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uiToolbarAddTo;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uiToolbarShuffle;
@property (weak, nonatomic) IBOutlet UIToolbar *uiToolbar;

@property (nonatomic) UILabel *titleLabel;

@end

@implementation AGAudioPlayerViewController

- (instancetype)initWithAudioPlayer:(AGAudioPlayer *)audioPlayer {
	if (self = [super initWithNibName:NSStringFromClass(AGAudioPlayerViewController.class)
							   bundle:nil]) {
		self.audioPlayer = audioPlayer;
		self.audioPlayer.delegate = self;
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

    self.uiProgressSlider.dataSource = self;
    self.uiProgressSlider.popUpViewCornerRadius = 2.0f;
    self.uiProgressSlider.popUpViewColor = self.darkForegroundColor;
    self.uiProgressSlider.textColor = self.lightForegroundColor;
	
    for (id current in self.uiVolumeView.subviews) {
        if ([current isKindOfClass:[UISlider class]]) {
            UISlider *volumeSlider = (UISlider *)current;
//            volumeSlider.minimumTrackTintColor = self.lightForegroundColor;
//            volumeSlider.maximumTrackTintColor = self.darkForegroundColor;
        }
    }
	
	NSArray *bts = @[self.uiToolbarRepeat,
					 self.uiToolbarAddTo,
					 self.uiToolbarShuffle];
	
	for (UIBarButtonItem *b in bts) {
		[b setTitleTextAttributes:@{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]}
						 forState:UIControlStateNormal];
	}
	
	self.uiToolbar.clipsToBounds = YES;
	
	self.titleLabel = [UILabel.alloc initWithFrame:CGRectMake(0, 0, 200, 44)];
	self.titleLabel.textAlignment = NSTextAlignmentCenter;
	self.navigationItem.titleView = self.titleLabel;
    
    [self.uiQueueTable registerNib:[UINib nibWithNibName:NSStringFromClass(AGAudioPlayerItemCell.class)
                                                  bundle:nil]
            forCellReuseIdentifier:@"cell"];
	
	[self redrawUI];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
	_backgroundColor = backgroundColor;
	
	self.view.backgroundColor = backgroundColor;
	self.uiToolbar.barTintColor = backgroundColor;
}

- (void)setForegroundColor:(UIColor *)foregroundColor {
	_foregroundColor = foregroundColor;
	
	if(self.uiBackwardButton == nil) {
		return;
	}
	
	NSArray *btns = @[self.uiBackwardButton,
					  self.uiPlayButton,
					  self.uiPauseButton,
					  self.uiForwardButton];
	
	for (UIButton *btn in btns) {
		[btn setImage:[self filledImageFrom:[btn imageForState:UIControlStateNormal]
								  withColor:self.foregroundColor]
			 forState:UIControlStateNormal];
	}
	
	self.uiTitleLabel.textColor =
	self.uiSubtitleLabel.textColor =
	self.uiTimeElapsedLabel.textColor =
	self.uiTimeRemainingLabel.textColor = self.foregroundColor;
}

- (void)foregroundHighlightColor:(UIColor *)foregroundHighlightColor {
	_foregroundHighlightColor = foregroundHighlightColor;
	
	if(self.uiBackwardButton == nil) {
		return;
	}
	
	NSArray *btns = @[self.uiBackwardButton,
					  self.uiPlayButton,
					  self.uiPauseButton,
					  self.uiForwardButton];
	
	for (UIButton *btn in btns) {
		[btn setImage:[self filledImageFrom:[btn imageForState:UIControlStateNormal]
								  withColor:self.foregroundHighlightColor]
			 forState:UIControlStateNormal];
	}
}

- (void)setLightForegroundColor:(UIColor *)lightForegroundColor {
	_lightForegroundColor = lightForegroundColor;

	if(self.uiBackwardButton == nil) {
		return;
	}
	
	self.uiProgressSlider.minimumTrackTintColor = lightForegroundColor;
    self.uiProgressSlider.textColor = self.lightForegroundColor;
}

- (void)setDarkForegroundColor:(UIColor *)darkForegroundColor {
	_darkForegroundColor = darkForegroundColor;
	
	if(self.uiBackwardButton == nil) {
		return;
	}
	
	self.uiProgressSlider.maximumTrackTintColor = darkForegroundColor;
    self.uiProgressSlider.popUpViewColor = self.darkForegroundColor;
}

- (void)setTintColor:(UIColor *)tintColor {
	_tintColor = tintColor;

    [UIToolbar appearanceWhenContainedIn:self.class, nil].tintColor = tintColor;
    [UISlider appearanceWhenContainedIn:self.class, nil].tintColor = tintColor;
    
	if(self.uiToolbar == nil) {
		return;
	}
    
	self.uiProgressSlider.tintColor = tintColor;
}

- (void)setupColorDefaults {
    if(self.foregroundColor == nil) {
        self.foregroundColor = UIColor.whiteColor;
    }
	else {
		self.foregroundColor = self.foregroundColor;
	}
    
    if(self.backgroundColor == nil) {
        self.backgroundColor = UIColor.blackColor;
    }
	else {
		self.backgroundColor = self.backgroundColor;
	}
	
	if(self.foregroundHighlightColor == nil) {
		self.foregroundHighlightColor = UIColor.lightGrayColor;
	}
	else {
		self.foregroundHighlightColor = self.foregroundHighlightColor;
	}
    
    if(self.lightForegroundColor == nil) {
        self.lightForegroundColor = UIColor.lightGrayColor;
    }
	else {
		self.lightForegroundColor = self.lightForegroundColor;
	}
    
    if(self.darkForegroundColor == nil) {
        self.darkForegroundColor = UIColor.darkGrayColor;
    }
	else {
		self.darkForegroundColor = self.darkForegroundColor;
	}
	
	if(self.tintColor == nil) {
		self.tintColor = UIColor.blueColor;
	}
	else {
		self.tintColor = self.tintColor;
	}
    
    self.view.backgroundColor = self.backgroundColor;
}

- (UIImage *)filledImageFrom:(UIImage *)source withColor:(UIColor *)color{
	
	// begin a new image context, to draw our colored image onto with the right scale
	UIGraphicsBeginImageContextWithOptions(source.size, NO, [UIScreen mainScreen].scale);
	
	// get a reference to that context we created
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// set the fill color
	[color setFill];
	
	// translate/flip the graphics context (for transforming from CG* coords to UI* coords
	CGContextTranslateCTM(context, 0, source.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	
	CGContextSetBlendMode(context, kCGBlendModeColorBurn);
	CGRect rect = CGRectMake(0, 0, source.size.width, source.size.height);
	CGContextDrawImage(context, rect, source.CGImage);
	
	CGContextSetBlendMode(context, kCGBlendModeSourceIn);
	CGContextAddRect(context, rect);
	CGContextDrawPath(context,kCGPathFill);
	
	// generate a new UIImage from the graphics context we drew onto
	UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	//return the color-burned image
	return coloredImg;
}

#pragma mark - Audio Player Delegate

- (void)audioPlayer:(AGAudioPlayer *)audioPlayer
uiNeedsRedrawForReason:(AGAudioPlayerRedrawReason)reason
		  extraInfo:(NSDictionary *)dict {
	[self redrawUI];
}

#pragma mark - UI Management

- (void)redrawUI {
	self.uiPlayButton.hidden = self.audioPlayer.isPlaying;
	self.uiPauseButton.hidden = !self.audioPlayer.isPlaying;
	
	self.uiForwardButton.enabled = !self.audioPlayer.isPlayingLastItem || self.audioPlayer.loopItem || self.audioPlayer.loopQueue;
	
	[self updateTitleView];
	
	if (self.audioPlayer.currentItem.albumArt) {
		self.uiAlbumArtImage.hidden = NO;
	}
	else {
		self.uiAlbumArtImage.hidden = YES;
	}
}

- (void)updateTitleView {
    if (self.audioPlayer.queue.count == 0) {
        self.titleLabel.attributedText = nil;
    }
    
	NSMutableAttributedString *s = NSMutableAttributedString.new;
	[s appendAttributedString:[NSAttributedString.alloc initWithString:@(self.audioPlayer.currentIndex + 1).stringValue
															attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:14.0f]}]];
	
	[s appendAttributedString:[NSAttributedString.alloc initWithString:@" of "
															attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14.0f]}]];
	
	[s appendAttributedString:[NSAttributedString.alloc initWithString:@(self.audioPlayer.queue.count).stringValue
															attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:14.0f]}]];
	
	self.titleLabel.attributedText = s;
}

- (NSString *)slider:(ASValueTrackingSlider *)slider
	  stringForValue:(float)value {
    return [AGDurationHelper formattedTimeWithInterval:self.audioPlayer.duration * value];
}

#pragma mark - Playback Queue Management

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.audioPlayer.queue.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AGAudioPlayerItemCell *cell = (AGAudioPlayerItemCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"
                                                                                           forIndexPath:indexPath];
    
    [cell updateCellWithAudioItem:self.audioPlayer.queue[indexPath.row]];
    
    return cell;
}

@end
