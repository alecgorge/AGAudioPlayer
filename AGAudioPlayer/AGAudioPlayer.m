//
//  AGAudioPlayer.m
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#import "AGAudioPlayer.h"

#import <BASSGaplessAudioPlayer/ObjectiveBASS.h>

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
@interface AGAudioPlayer () <AVAudioSessionDelegate, AGAudioPlayerUpNextQueueDelegate, ObjectiveBASSDelegate, ObjectiveBASSDataSource>
#else
@interface AGAudioPlayer () <AGAudioPlayerUpNextQueueDelegate, ObjectiveBASSDelegate, ObjectiveBASSDataSource>
#endif
{
}

@property BOOL registeredAudioSession;
@property BOOL wasPlayingDuringInterruption;

@property (nonatomic) ObjectiveBASS *bass;

@property (nonatomic) NSMutableArray<AGAudioPlayerHistoryItem *> *playbackHistory;

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
    [self setupBASS];
}

- (void)dealloc {
    [self teardownBASS];
}

#pragma mark - Playback Control

- (BOOL)isPlaying {
    return self.bass.currentState == BassPlaybackStatePlaying;
}

- (BOOL)isBuffering {
    return self.bass.currentState == BassPlaybackStateStalled;
}

- (BOOL)isPlayingFirstItem {
    return self.currentIndex == 0;
}

- (BOOL)isPlayingLastItem {
    return self.currentIndex == self.queue.count - 1;
}

- (void)setShuffle:(BOOL)shuffle {
    _shuffle = shuffle;
}

- (void)setLoopItem:(BOOL)loopItem {
    _loopItem = loopItem;
}

- (void)setLoopQueue:(BOOL)loopQueue {
    _loopQueue = loopQueue;
}

- (void)resume {
    if(!self.isPlaying) {
        [self.bass resume];
    }
}

- (void)pause {
    if (self.isPlaying)	{
        [self.bass pause];
    }
}

- (void)stop {
    [self.bass stop];
}

- (void)forward {
    self.currentIndex = self.nextIndex;
}

- (void)backward {
    if(self.elapsed < 5.0f || self.backwardStyle == AGAudioPlayerBackwardStyleAlwaysPrevious) {
        self.currentIndex = self.previousIndex;
    }
    else {
        [self seekTo:0];
    }
}

- (void)seekTo:(NSTimeInterval)i {
    [self seekToPercent:i / self.duration];
}

- (void)seekToPercent:(CGFloat)per {
    [self.bass seekToPercent:per];
}

- (NSTimeInterval)duration {
    return self.bass.currentDuration;
}

- (NSTimeInterval)elapsed {
    return self.bass.elapsed;
}

- (CGFloat)percentElapsed {
    return self.elapsed / self.duration;
}

#pragma mark - Playback Order

- (void)setIndex:(NSInteger)index {
    _currentIndex = index;
}

- (void)setCurrentIndex:(NSInteger)currentIndex {
    [self setCurrentIndex:currentIndex
           loggingHistory:NO];
}

- (void)setCurrentIndex:(NSInteger)currentIndex
         loggingHistory:(BOOL)history {
    if(history) {
        [self.playbackHistory addObject:[AGAudioPlayerHistoryItem.alloc initWithQueue:self.queue
                                                                             andIndex:self.currentIndex]];
    }
    
    _currentIndex = currentIndex;
    
    AGAudioItem * item = [self.queue properQueueForShuffleEnabled:self.shuffle][currentIndex];
    
    [self.bass playURL:item.playbackURL
        withIdentifier:item.playbackGUID];
    
    [self.delegate audioPlayer:self
        uiNeedsRedrawForReason:AGAudioPlayerRedrawReasonTrackChanged];
}

- (void)playItemAtIndex:(NSUInteger)idx {
    self.currentIndex = idx;
}

- (AGAudioItem *)currentItem {
    if(self.currentIndex == -1 || self.currentIndex >= self.queue.count) {
        return nil;
    }
    
    return [self.queue properQueueForShuffleEnabled:self.shuffle][self.currentIndex];
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

- (AGAudioItem *)nextItem {
    NSInteger nextIndex = self.nextIndex;
    
    if(nextIndex == NSNotFound || nextIndex >= self.queue.count) {
        return nil;
    }
    
    return [self.queue properQueueForShuffleEnabled:self.shuffle][self.nextIndex];
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

- (AGAudioItem *)previousItem {
    return self.lastHistoryEntry.queue[self.lastHistoryEntry.index];
}

- (void)incrementIndex {
    _currentIndex = self.nextIndex;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@<%p>:\n    state: %@\n    shuffle: %d, loop: %d\n    currentItem (index: %ld): %@\n    playback: %.2f/%.2f (%.2f%%)", NSStringFromClass(self.class), self, [self stringForState:self.bass.currentState], self.shuffle, self.loopItem || self.loopQueue, (long)self.currentIndex, self.currentItem, self.elapsed, self.duration, self.percentElapsed * 100.0f];
}

#pragma mark - History management

- (void)setupHistory {
    self.playbackHistory = NSMutableArray.array;
}

- (void)resetHistory {
    [self.playbackHistory removeAllObjects];
}

#pragma mark - FreeStreamer management

- (void)setupBASS {
    self.bass = ObjectiveBASS.new;
}

- (void)teardownBASS {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    self.bass = nil;
}

- (NSString *)stringForState:(BassPlaybackState)status {
    switch (status) {
        case BassPlaybackStateStopped:
            return @"Retriving URL";
            
        case BassPlaybackStateStalled:
            return @"Stopped";
            
        case BassPlaybackStatePlaying:
            return @"Buffering";
            
        case BassPlaybackStatePaused:
            return @"Seeking";

        default:
            return [NSString stringWithFormat:@"Unknown state: %ld", status];
    }
}

- (NSString *)stringForErrorCode:(BassStreamError)errorCode {
    return [self.bass errorForErrorCode:errorCode].localizedDescription;
}

- (void)debug:(NSString *)str, ... {
    va_list args;
    va_start(args, str);
    NSString *s = [NSString.alloc initWithFormat:str
                                       arguments:args];
    NSLog(@"[AGAudioPlayer] %@", s);
    va_end(args);
}

-(void)BASSDownloadPlaybackStateChanged:(BassPlaybackState)state {
    switch (state) {
        case BassPlaybackStatePaused:
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerRedrawReasonPaused];
            
            break;
            
        case BassPlaybackStatePlaying:
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerRedrawReasonPlaying];
            
            break;
            
        case BassPlaybackStateStalled:
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerRedrawReasonBuffering];
            
            break;
            
        case BassPlaybackStateStopped:
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerRedrawReasonStopped];
            
            break;
            
        default:
            break;
    }
}

- (void)BASSErrorStartingStream:(NSError *)error
                         forURL:(NSURL *)url
                 withIdentifier:(NSUUID *)identifier {
    [self.delegate audioPlayer:self
                   errorRaised:error
                        forURL:url];
}

- (void)BASSDownloadProgressChanged:(BOOL)forActiveTrack
                    downloadedBytes:(uint64_t)downloadedBytes
                         totalBytes:(uint64_t)totalBytes {
    if(!forActiveTrack) return;
    
    [self.delegate audioPlayer:self
 downloadedBytesForActiveTrack:downloadedBytes
                    totalBytes:totalBytes];
}

- (void)BASSPlaybackProgressChanged:(NSTimeInterval)elapsed
                  withTotalDuration:(NSTimeInterval)totalDuration {
    [self.delegate audioPlayer:self
               progressChanged:elapsed
             withTotalDuration:totalDuration];
}

- (CGFloat)volume {
    return self.bass.volume;
}

- (void)setVolume:(CGFloat)volume {
    self.bass.volume = volume;
}

#pragma mark - Queue delegate

- (BOOL)BASSIsPlayingLastTrack:(nonnull ObjectiveBASS *)bass
                       withURL:(nonnull NSURL *)url
                 andIdentifier:(nonnull NSUUID *)identifier {
    return self.queue.count - 1 == [self.queue properPositionForId:identifier
                                                 forShuffleEnabled:self.shuffle];
}

- (nonnull NSUUID *)BASSNextTrackIdentifier:(nonnull ObjectiveBASS *)bass
                                   afterURL:(nonnull NSURL *)url
                             withIdentifier:(nonnull NSUUID *)identifier {
    return self.nextItem.playbackGUID;
}

- (void)BASSLoadNextTrackURL:(nonnull ObjectiveBASS *)bass
               forIdentifier:(nonnull NSUUID *)identifier {
    NSURL *url = [self.queue itemForId:identifier].playbackURL;

    [self.bass nextTrackURLLoaded:url];
}

- (void)upNextQueueRemovedAllItems:(AGAudioPlayerUpNextQueue *)queue {
    _currentIndex = -1;
    
    [self stop];
}

- (void)upNextQueue:(AGAudioPlayerUpNextQueue *)queue
          addedItem:(AGAudioItem *)item
            atIndex:(NSInteger)idx {
    if(idx <= self.currentIndex) {
        _currentIndex++;
    }
    
    [self.bass nextTrackMayHaveChanged];
    
    [self.delegate audioPlayer:self
        uiNeedsRedrawForReason:AGAudioPlayerRedrawReasonQueueChanged];
}

- (void)upNextQueue:(AGAudioPlayerUpNextQueue *)queue
        removedItem:(AGAudioItem *)item
          fromIndex:(NSInteger)idx {
    if(idx == self.currentIndex) {
        [self.playbackHistory addObject:[AGAudioPlayerHistoryItem.alloc initWithQueue:queue
                                                                             andIndex:idx]];
        
        [self setCurrentIndex:idx
               loggingHistory:NO];
    }
    else {
        [self.bass nextTrackMayHaveChanged];
    }
    
    [self.delegate audioPlayer:self
        uiNeedsRedrawForReason:AGAudioPlayerRedrawReasonQueueChanged];
}

-(void)upNextQueue:(AGAudioPlayerUpNextQueue *)queue
         movedItem:(AGAudioItem *)item
         fromIndex:(NSInteger)oldIndex
           toIndex:(NSInteger)newIndex {
    [self debug:@"old currentIndex: %d", self.currentIndex];
    
    if(oldIndex == self.currentIndex) {
        _currentIndex = newIndex;
    }
    else if(oldIndex < self.currentIndex && newIndex > self.currentIndex) {
        _currentIndex--;
    }
    else if(oldIndex > self.currentIndex && newIndex <= self.currentIndex) {
        _currentIndex++;
    }

    [self debug:@"new currentIndex: %d", self.currentIndex];
    
    [self.bass nextTrackMayHaveChanged];
    
    [self.delegate audioPlayer:self
        uiNeedsRedrawForReason:AGAudioPlayerRedrawReasonQueueChanged];
}

@end
