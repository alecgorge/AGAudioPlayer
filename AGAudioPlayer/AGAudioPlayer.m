//
//  AGAudioPlayer.m
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#import "AGAudioPlayer.h"

#import <HysteriaPlayer/HysteriaPlayer.h>

@interface AGAudioPlayerHistoryItem : NSObject

@property (nonatomic) AGAudioPlayerUpNextQueue *queue;
@property (nonatomic) NSInteger index;

- (instancetype)initWithQueue:(AGAudioPlayerUpNextQueue *)queue
                     andIndex:(NSInteger)index;

@end

@implementation AGAudioPlayerHistoryItem

- (instancetype)initWithQueue:(AGAudioPlayerUpNextQueue *)queue
                     andIndex:(NSInteger)index {
    if (self = [super init]) {
        self.queue = queue;
        self.index = index;
    }
    
    return self;
}

@end

#if TARGET_OS_IPHONE
@interface AGAudioPlayer () <AVAudioSessionDelegate, HysteriaPlayerDelegate, HysteriaPlayerDataSource, AGAudioPlayerUpNextQueueDelegate>
#else
@interface AGAudioPlayer () <HysteriaPlayerDelegate, HysteriaPlayerDataSource, AGAudioPlayerUpNextQueueDelegate>
#endif

@property BOOL registeredAudioSession;
@property BOOL wasPlayingDuringInterruption;

@property (nonatomic) HysteriaPlayer *hPlayer;

@property (nonatomic) NSMutableArray *playbackHistory;

@property (nonatomic) NSTimer *playbackUpdateTimer;

@end

@implementation AGAudioPlayer

#pragma mark - Object Lifecycle

- (instancetype)initWithQueue:(AGAudioPlayerUpNextQueue *)queue {
    if (self = [super init]) {
        self.queue = queue;
        self.queue.delegate = self;
        [self setup];
    }
    return self;
}

- (void)setup {
    [self setupHysteria];
    
    self.playbackUpdateTimeInterval = 1.0f;
}

- (void)dealloc {
    [self teardownHysteria];
}

#pragma mark - Playback Control

- (BOOL)isPlaying {
    return self.hPlayer.isPlaying;
}

- (BOOL)isBuffering {
    return self.hPlayer.getHysteriaPlayerStatus == HysteriaPlayerStatusBuffering;
}

- (BOOL)isPlayingFirstItem {
    return self.currentIndex == 0;
}

- (BOOL)isPlayingLastItem {
    return self.currentIndex == self.queue.count - 1;
}

- (void)setShuffle:(BOOL)shuffle {
    _shuffle = shuffle;
    [self.hPlayer setPlayerShuffleMode:shuffle ? HysteriaPlayerShuffleModeOn : HysteriaPlayerShuffleModeOff];
}

- (void)setLoopItem:(BOOL)loopItem {
    _loopItem = loopItem;
    [self.hPlayer setPlayerRepeatMode:loopItem ? HysteriaPlayerRepeatModeOnce : HysteriaPlayerRepeatModeOff];
}

- (void)setLoopQueue:(BOOL)loopQueue {
    _loopQueue = loopQueue;
    [self.hPlayer setPlayerRepeatMode:loopQueue ? HysteriaPlayerRepeatModeOn : HysteriaPlayerRepeatModeOff];
}

- (void)resume {
    if(!self.hPlayer.isPlaying) {
        [self.hPlayer pausePlayerForcibly:NO];
        [self.hPlayer play];
    }
}

- (void)pause {
    if (self.hPlayer.isPlaying)	{
        [self.hPlayer pausePlayerForcibly:YES];
        [self.hPlayer pause];
    }
}

- (void)stop {
    [self pause];
    
    [self.delegate audioPlayer:self
        uiNeedsRedrawForReason:AGAudioPlayerTrackStopped
                     extraInfo:nil];
}

- (void)forward {
    [self.hPlayer playNext];
    //	self.currentIndex = self.nextIndex;
}

- (void)backward {
    if(self.elapsed < 5.0f || self.backwardStyle == AGAudioPlayerBackwardStyleAlwaysPrevious) {
        [self.hPlayer playPrevious];
        //		NSInteger lastIndex = self.previousIndex;
        //		[self.playbackHistory removeLastObject];
        //		self.currentIndex = lastIndex;
    }
    else {
        [self seekTo:0];
    }
}

- (void)seekTo:(NSTimeInterval)i {
    [self.hPlayer seekToTime:i];
}

- (void)seekToPercent:(CGFloat)per {
    [self.hPlayer seekToTime:per * self.duration];
}

- (NSTimeInterval)duration {
    return self.hPlayer.getPlayingItemDurationTime;
}

- (NSTimeInterval)elapsed {
    return self.hPlayer.getPlayingItemCurrentTime;
}

- (CGFloat)percentElapsed {
    return self.elapsed / self.duration;
}

#pragma mark - Playback Order

- (void)setIndex:(NSInteger)index {
    _currentIndex = index;
}

- (void)setCurrentIndex:(NSInteger)currentIndex {
    [self.playbackHistory addObject:[AGAudioPlayerHistoryItem.alloc initWithQueue:self.queue
                                                                         andIndex:self.currentIndex]];
    _currentIndex = currentIndex;
    
    [self stop];
    
    [self.currentItem loadMetadata:^(id<AGAudioItem> i) {
        [self.hPlayer fetchAndPlayPlayerItem:currentIndex];
    }];
    
    [self.nextItem loadMetadata:^(id<AGAudioItem> i) {
        
    }];
}

- (void)playItemAtIndex:(NSUInteger)idx {
    self.currentIndex = idx;
}

- (id<AGAudioItem>)currentItem {
    if(self.currentIndex == -1 || self.currentIndex >= self.queue.count) {
        return nil;
    }
    
    return self.queue[self.currentIndex];
}

- (NSInteger)nextIndex {
    // looping a single track
    if (self.loopItem) {
        return self.currentIndex;
    }
    
    // last song in the current queue
    if (self.currentIndex == self.queue.count) {
        // start the current queue from the beginning
        if(self.loopQueue) {
            return 0;
        }
        // reached the end of all tracks, accross both queues
        else {
            return NSNotFound;
        }
    }
    // there are still songs in the current queue
    else {
        return self.currentIndex + 1;
    }
}

- (id<AGAudioItem>)nextItem {
    NSInteger nextIndex = self.nextIndex;
    
    if(nextIndex == NSNotFound || nextIndex >= self.queue.count) {
        return nil;
    }
    
    return self.queue[self.nextIndex];
}

- (AGAudioPlayerHistoryItem *)lastHistoryEntry {
    return self.playbackHistory.lastObject;
}

- (NSInteger)previousIndex {
    AGAudioPlayerHistoryItem *l = self.lastHistoryEntry;
    if (l == nil) {
        return NSNotFound;
    }
    
    return l.index;
}

- (id<AGAudioItem>)previousItem {
    return self.lastHistoryEntry.queue[self.lastHistoryEntry.index];
}

- (void)incrementIndex {
    _currentIndex = self.nextIndex;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@<%p>:\n    state: %@\n    shuffle: %d, loop: %d\n    currentItem (index: %ld): %@\n    playback: %.2f/%.2f (%.2f%%)", NSStringFromClass(self.class), self, [self stringForState:self.hPlayer.getHysteriaPlayerStatus], self.shuffle, self.loopItem || self.loopQueue, (long)self.currentIndex, self.currentItem, self.elapsed, self.duration, self.percentElapsed * 100.0f];
}

#pragma mark - History management

- (void)setupHistory {
    self.playbackHistory = NSMutableArray.array;
}

- (void)resetHistory {
    [self.playbackHistory removeAllObjects];
}

#pragma mark - Playback Updates

- (void)startPlaybackUpdatesWithInterval:(NSTimeInterval)i {
    if (self.playbackUpdateTimer) {
        [self.playbackUpdateTimer invalidate];
    }
    
    self.playbackUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:i
                                                                target:self
                                                              selector:@selector(sendPlaybackUpdate)
                                                              userInfo:nil
                                                               repeats:YES];
    
    [self sendPlaybackUpdate];
}

- (void)stopPlaybackUpdates {
    [self.playbackUpdateTimer invalidate];
}

- (void)sendPlaybackUpdate {
    [self.delegate audioPlayer:self
        uiNeedsRedrawForReason:AGAudioPlayerTrackProgressUpdated
                     extraInfo:nil];
}

#pragma mark - Hysteria management

- (void)setupHysteria {
    self.hPlayer = HysteriaPlayer.sharedInstance;
    self.hPlayer.delegate = self;
    self.hPlayer.datasource = self;
    self.hPlayer.disableLogs = NO;
    [self.hPlayer setPlayerRepeatMode:HysteriaPlayerRepeatModeOff];
    
#if TARGET_OS_IPHONE
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(audioInteruptionOccured:)
                                               name:AVAudioSessionInterruptionNotification
                                             object:nil];
#endif
    
}

- (AVQueuePlayer *)player {
    return self.hPlayer.audioPlayer;
}

- (void)teardownHysteria {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (NSString *)stringForState:(HysteriaPlayerStatus)status {
    switch (status) {
        case HysteriaPlayerStatusBuffering:
            return @"Buffering";
        case HysteriaPlayerStatusPlaying:
            return @"Playing";
        case HysteriaPlayerStatusUnknown:
            return @"Unknown";
        case HysteriaPlayerStatusForcePause:
            return @"Paused";
        default:
            return @"Unknown!?";
    }
}

- (NSString *)stringForErrorCode:(HysteriaPlayerFailed)status {
    switch (status) {
        case HysteriaPlayerFailedPlayer:
            return @"Error: Player";
        case HysteriaPlayerFailedCurrentItem:
            return @"Error: Current item";
        default:
            return @"Error: unknown";
    }
}

- (void)debug:(NSString *)str, ... {
    va_list args;
    va_start(args, str);
    NSString *s = [NSString.alloc initWithFormat:str
                                       arguments:args];
    NSLog(@"[AGAudioPlayer] %@", s);
    va_end(args);
}

#pragma mark - Hysteria Datasource

- (void)upNextQueueRemovedAllItems:(AGAudioPlayerUpNextQueue *)queue {
    _currentIndex = -1;
    
    [self stop];
}

-(void)upNextQueue:(AGAudioPlayerUpNextQueue *)queue
       swappedItem:(id<AGAudioItem>)item
           atIndex:(NSInteger)oldIndex
          withItem:(id<AGAudioItem>)item2
           atIndex:(NSInteger)oldIndex2 {
    [self.hPlayer moveItemFromIndex:oldIndex
                            toIndex:oldIndex2];
}

- (void)upNextQueue:(AGAudioPlayerUpNextQueue *)queue
        removedItem:(id<AGAudioItem>)item
          fromIndex:(NSInteger)idx {
    [self.hPlayer removeItemAtIndex:idx];
}

- (NSInteger)hysteriaPlayerNumberOfItems {
    return self.queue.count;
}

- (NSURL *)hysteriaPlayerURLForItemAtIndex:(NSInteger)index
                                 preBuffer:(BOOL)preBuffer {
    return [self.queue[index] playbackURL];
}

#pragma mark - Hysteria Delegate

- (void)hysteriaPlayerDidFailed:(HysteriaPlayerFailed)identifier
                          error:(NSError *)error {
    [self debug:@"Hysteria: error: %@", error];
    
    [self.delegate audioPlayer:self
        uiNeedsRedrawForReason:AGAudioPlayerTrackProgressUpdated
                     extraInfo:nil];
}

- (void)hysteriaPlayerWillChangedAtIndex:(NSInteger)index {
	[self debug:@"Hysteria: Player will changed at index: %d", index];
    
    _currentIndex = index;

	[self.delegate audioPlayer:self
		uiNeedsRedrawForReason:AGAudioPlayerTrackPlaying
					 extraInfo:nil];
}

- (void)hysteriaPlayerCurrentItemChanged:(AVPlayerItem *)item {
    [self debug:@"Hysteria: Current item changed: %@", item];
    
    [self.delegate audioPlayer:self
        uiNeedsRedrawForReason:AGAudioPlayerTrackProgressUpdated
                     extraInfo:nil];
}

- (void)hysteriaPlayerRateChanged:(BOOL)isPlaying {
    [self debug:@"Hysteria: playing: %d", isPlaying];
    
    if(isPlaying) {
        [self startPlaybackUpdatesWithInterval:self.playbackUpdateTimeInterval];
    }
    else {
        [self stopPlaybackUpdates];
    }
    
    [self.delegate audioPlayer:self
        uiNeedsRedrawForReason:isPlaying ? AGAudioPlayerTrackPlaying : AGAudioPlayerTrackPaused
                     extraInfo:nil];
}

- (void)hysteriaPlayerDidReachEnd {
    [self debug:@"Hysteria: did reach end"];
	
	[self.delegate audioPlayer:self
		uiNeedsRedrawForReason:AGAudioPlayerTrackProgressUpdated
					 extraInfo:nil];
}

- (void)hysteriaPlayerCurrentItemPreloaded:(CMTime)time {
    [self debug:@"Hysteria: current item preloaded to: %f", CMTimeGetSeconds(time)];
}

- (void)hysteriaPlayerReadyToPlay:(HysteriaPlayerReadyToPlay)identifier {
    [self debug:@"Hysteria: ready to play: %d", identifier];
    
    if(identifier == HysteriaPlayerReadyToPlayPlayer) {
        [self.delegate audioPlayer:self
            uiNeedsRedrawForReason:AGAudioPlayerTrackPaused
                         extraInfo:nil];
    }
    else {
        [self.delegate audioPlayer:self
            uiNeedsRedrawForReason:AGAudioPlayerTrackPlaying
                         extraInfo:nil];
    }
    
    [self resume];
}

#pragma mark - Interruption Handling

- (void)registerAudioSession {
    if (!self.registeredAudioSession) {
        //        [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback
        //                                             error:nil];
        //
        //        [AVAudioSession.sharedInstance setActive:YES
        //                                           error:nil];
        
#if TARGET_OS_IPHONE
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(audioRouteChanged:)
                                                   name:AVAudioSessionRouteChangeNotification
                                                 object:nil];
#endif
        
        self.registeredAudioSession = YES;
        
        //        [NSNotificationCenter.defaultCenter addObserver:self
        //                                               selector:@selector(audioInteruptionOccured:)
        //                                                   name:AVAudioSessionInterruptionNotification
        //                                                 object:nil];
    }
}

- (void)audioRouteChanged:(NSNotification *)notification {
#if TARGET_OS_IPHONE
    NSNumber *reason = notification.userInfo[AVAudioSessionRouteChangeReasonKey];
    
    if(reason.integerValue == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        [self pause];
    }
#endif
}

- (void)audioInteruptionOccured:(NSNotification *)notification {
#if TARGET_OS_IPHONE
    NSDictionary *interruptionDictionary = notification.userInfo;
    AVAudioSessionInterruptionType interruptionType = [interruptionDictionary[AVAudioSessionInterruptionTypeKey] integerValue];
    
    switch (interruptionType) {
        case AVAudioSessionInterruptionTypeBegan: {
            [self debug:@"AVAudioSession: interruption began"];
            
            self.wasPlayingDuringInterruption = self.isPlaying;
            
            if ([self.delegate respondsToSelector:@selector(audioPlayerBeginInterruption:)]) {
                [self.delegate audioPlayerBeginInterruption:self];
            }
            else {
                [self pause];
            }
        }
            
            break;
        case AVAudioSessionInterruptionTypeEnded: {
            AVAudioSessionInterruptionOptions options = [interruptionDictionary[AVAudioSessionInterruptionOptionKey] integerValue];
            
            BOOL resume = options == AVAudioSessionInterruptionOptionShouldResume && self.wasPlayingDuringInterruption;
            
            [self debug:@"AVAudioSession: interruption ended, should resume: %@", resume ? @"YES" : @"NO"];
            
            if ([self.delegate respondsToSelector:@selector(audioPlayerEndInterruption:shouldResume:)]) {
                [self.delegate audioPlayerEndInterruption:self
                                             shouldResume:resume];
            }
            else {
                if(resume) {
                    [self resume];
                }
            }
        }
            break;
            
        default:
            break;
    }
#endif
}

@end
