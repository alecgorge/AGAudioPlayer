//
//  AGAudioPlayer.h
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#import <UIKit/UIKit.h>

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

- (AGAudioItem *)audioPlayer:(AGAudioPlayer *)audioPlayer
audioItemForUpcomingTrackIndex:(NSInteger)upcomingTrackIndex;

@end

typedef NS_ENUM(NSInteger, AGAudioPlayerRedrawReason) {
	AGAudioPlayerTrackProgressUpdated,
	AGAudioPlayerTrackBuffering,
	AGAudioPlayerTrackPlaying,
    AGAudioPlayerTrackStopped,
    AGAudioPlayerTrackPaused,
    AGAudioPlayerError,
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

@property (nonatomic) AGAudioPlayerUpNextQueue *queue;

@property (nonatomic, readonly) NSInteger currentIndex;
@property (nonatomic, readonly) AGAudioItem *currentItem;

// returns NSNotFound when last item is playing
@property (nonatomic, readonly) NSInteger nextIndex;

// returns nil when last item is playing
@property (nonatomic, readonly) AGAudioItem *nextItem;

// returns NSNotFound when the first item playing
@property (nonatomic, readonly) NSInteger previousIndex;

// returns nil when the first item is playing
@property (nonatomic, readonly) AGAudioItem *previousItem;

// playback control
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic) BOOL shuffle;

// loops
@property (nonatomic) BOOL loopQueue;
@property (nonatomic) BOOL loopItem;

- (void)resume;
- (void)pause;
- (void)stop;

- (void)forward;
- (void)backward;

- (void)seekTo:(NSTimeInterval)i;
- (void)seekToPercent:(CGFloat)per;

// info
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic) NSTimeInterval elapsed;
@property (nonatomic) CGFloat percentElapsed;

@end
