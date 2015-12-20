//
//  AGAudioPlayer.h
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import <AVFoundation/AVFoundation.h>
#import "AGAudioItem.h"
#import "AGAudioPlayerUpNextQueue.h"

typedef NS_ENUM(NSInteger, AGAudioPlayerBackwardStyle) {
    AGAudioPlayerBackwardStyleRestartTrack,
    AGAudioPlayerBackwardStyleAlwaysPrevious
};

@class AGAudioPlayer;

@protocol AGAudioPlayerUpcomingQueueDelegate <NSObject>

- (NSInteger)audioPlayer:(AGAudioPlayer *)audioPlayer
  numberOfUpcomingTracks:upcomingTracks;

- (id<AGAudioItem>)audioPlayer:(AGAudioPlayer *)audioPlayer
audioItemForUpcomingTrackIndex:(NSInteger)upcomingTrackIndex;

@end

typedef NS_ENUM(NSInteger, AGAudioPlayerRedrawReason) {
    AGAudioPlayerTrackProgressUpdated,
    AGAudioPlayerTrackBuffering,
    AGAudioPlayerTrackPlaying,
    AGAudioPlayerTrackStopped,
    AGAudioPlayerTrackPaused,
    AGAudioPlayerError,
    AGAudioPlayerTrackChanged,
};

@protocol AGAudioPlayerDelegate <NSObject>

- (void)audioPlayer:(AGAudioPlayer *)audioPlayer
uiNeedsRedrawForReason:(AGAudioPlayerRedrawReason)reason
          extraInfo:(NSDictionary *)dict;

@optional

// OPTIONAL: if not implemented, will pause playback
- (void)audioPlayerBeginInterruption:(AGAudioPlayer *)audioPlayer;

// OPTIONAL: if not implemented, will resume playback if resume == YES
- (void)audioPlayerEndInterruption:(AGAudioPlayer *)audioPlayer
                      shouldResume:(BOOL)resume;

@end

// delegate for redraw with reason

@interface AGAudioPlayer : NSObject

- (instancetype)initWithQueue:(AGAudioPlayerUpNextQueue *)queue;

@property (nonatomic, weak) id<AGAudioPlayerDelegate> delegate;

@property (nonatomic) NSTimeInterval playbackUpdateTimeInterval;

@property (nonatomic) AGAudioPlayerUpNextQueue *queue;
@property (nonatomic, readonly) AVQueuePlayer *player;

@property (nonatomic) NSInteger currentIndex;
@property (nonatomic, readonly) id<AGAudioItem> currentItem;

// returns NSNotFound when last item is playing
@property (nonatomic, readonly) NSInteger nextIndex;

// returns nil when last item is playing
@property (nonatomic, readonly) id<AGAudioItem> nextItem;

// returns NSNotFound when the first item playing
@property (nonatomic, readonly) NSInteger previousIndex;

// returns nil when the first item is playing
@property (nonatomic, readonly) id<AGAudioItem> previousItem;

// playback control
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) BOOL isBuffering;
@property (nonatomic, readonly) BOOL isPlayingFirstItem;
@property (nonatomic, readonly) BOOL isPlayingLastItem;

@property (nonatomic) BOOL shuffle;

// loops
@property (nonatomic) BOOL loopQueue;
@property (nonatomic) BOOL loopItem;

@property (nonatomic) AGAudioPlayerBackwardStyle backwardStyle;

- (void)setIndex:(NSInteger)index;

- (void)resume;
- (void)pause;
- (void)stop;

- (void)forward;
- (void)backward;

- (void)seekTo:(NSTimeInterval)i;
- (void)seekToPercent:(CGFloat)per;

- (void)playItemAtIndex:(NSUInteger)idx;

// info
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) NSTimeInterval elapsed;
@property (nonatomic, readonly) CGFloat percentElapsed;

@end
