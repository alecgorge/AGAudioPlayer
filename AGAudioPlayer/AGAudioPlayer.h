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

@protocol AGAudioPlayerImplicitUpcomingQueueDelegate <NSObject>

- (NSInteger)audioPlayer:(AGAudioPlayer *)audioPlayer
numberOfImplicitUpcomingTracks:upcomingTracks;

- (AGAudioItem *)audioPlayer:(AGAudioPlayer *)audioPlayer
implicitAudioItemForUpcomingTrackIndex:(NSInteger)upcomingTrackIndex;

@end

@protocol AGAudioPlayerExplicitUpcomingQueueDelegate <NSObject>

- (NSInteger)audioPlayer:(AGAudioPlayer *)audioPlayer
numberOfExplicitUpcomingTracks:upcomingTracks;

- (AGAudioItem *)audioPlayer:(AGAudioPlayer *)audioPlayer
explicitAudioItemForUpcomingTrackIndex:(NSInteger)upcomingTrackIndex;

@end

@interface AGAudioPlayer : NSObject

- (instancetype)initWithExplicitQueue:(AGAudioPlayerUpNextQueue *)ex
                     andImplicitQueue:(AGAudioPlayerUpNextQueue *)im;

@property (nonatomic) AGAudioPlayerUpNextQueue *explicitUpcomingQueue;
@property (nonatomic) AGAudioPlayerUpNextQueue *implicitUpcomingQueue;

@property (nonatomic, readonly) AGAudioPlayerUpNextQueue *currentQueue;
@property (nonatomic, readonly) NSInteger currentIndex;
@property (nonatomic, readonly) AGAudioItem *currentItem;

@property (nonatomic, readonly) AGAudioPlayerUpNextQueue *nextQueue;
@property (nonatomic, readonly) NSInteger nextIndex;
@property (nonatomic, readonly) AGAudioItem *nextItem;


// playback control
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic) BOOL shuffle;
@property (nonatomic) BOOL loopQueue;
@property (nonatomic) BOOL loopItem;

@property (nonatomic) CGFloat volume;

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
