//
//  AGAudioPlayer.m
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#import "AGAudioPlayer.h"

#import <FreeStreamer/FSAudioStream.h>
#import <FreeStreamer/FSAudioController.h>
#import <FreeStreamer/FSPlaylistItem.h>

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
@interface AGAudioPlayer () <AVAudioSessionDelegate, AGAudioPlayerUpNextQueueDelegate>
#else
@interface AGAudioPlayer () <AGAudioPlayerUpNextQueueDelegate>
#endif
{
    BOOL _isBuffering;
    FSAudioStreamState _state;
}

@property BOOL registeredAudioSession;
@property BOOL wasPlayingDuringInterruption;

@property (nonatomic) FSAudioController *fsAudio;

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
    [self setupFreeStreamer];

    self.playbackUpdateTimeInterval = 1.0f;
}

- (void)dealloc {
    [self teardownFreeStreamer];
}

#pragma mark - Playback Control

- (BOOL)isPlaying {
    return self.fsAudio.isPlaying;
}

- (BOOL)isBuffering {
    return _isBuffering;
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
        [self.fsAudio pause];
    }
}

- (void)pause {
    if (self.isPlaying)	{
        [self.fsAudio pause];
    }
}

- (void)stop {
    [self.fsAudio stop];
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
    FSStreamPosition pos;
    pos.position = per;
    [self.fsAudio.activeStream seekToPosition:pos];
}

- (NSTimeInterval)duration {
    return self.fsAudio.activeStream.duration.playbackTimeInSeconds;
}

- (NSTimeInterval)elapsed {
    return self.fsAudio.activeStream.currentTimePlayed.playbackTimeInSeconds;
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
    
    [self.fsAudio playItemAtIndex:currentIndex];
    
    [self.delegate audioPlayer:self
        uiNeedsRedrawForReason:AGAudioPlayerTrackChanged
                     extraInfo:nil];
}

- (void)playItemAtIndex:(NSUInteger)idx {
    self.currentIndex = idx;
}

- (id<AGAudioItem>)currentItem {
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

- (id<AGAudioItem>)nextItem {
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

- (id<AGAudioItem>)previousItem {
    return self.lastHistoryEntry.queue[self.lastHistoryEntry.index];
}

- (void)incrementIndex {
    _currentIndex = self.nextIndex;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@<%p>:\n    state: %@\n    shuffle: %d, loop: %d\n    currentItem (index: %ld): %@\n    playback: %.2f/%.2f (%.2f%%)", NSStringFromClass(self.class), self, [self stringForState:_state], self.shuffle, self.loopItem || self.loopQueue, (long)self.currentIndex, self.currentItem, self.elapsed, self.duration, self.percentElapsed * 100.0f];
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

#pragma mark - FreeStreamer management

- (void)setupFreeStreamer {
    self.fsAudio = FSAudioController.new;
    
    self.fsAudio.configuration.cacheEnabled = YES;
    self.fsAudio.configuration.cacheDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"AGAudioPlayer_cache"];
    self.fsAudio.configuration.automaticAudioSessionHandlingEnabled = YES;
    self.fsAudio.configuration.maxPrebufferedByteCount = 30 * 1024 * 1024; // 30 MB
    self.fsAudio.configuration.seekingFromCacheEnabled = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fsAudioStreamStateDidChange:)
                                                 name:FSAudioStreamStateChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fsAudioStreamErrorOccurred:)
                                                 name:FSAudioStreamErrorNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fsAudioStreamMetaDataAvailable:)
                                                 name:FSAudioStreamMetaDataNotification
                                               object:nil];
}

- (void)teardownFreeStreamer {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (NSString *)stringForState:(FSAudioStreamState)status {
    switch (status) {
        case kFsAudioStreamRetrievingURL:
            return @"Retriving URL";
            
        case kFsAudioStreamStopped:
            return @"Stopped";
            
        case kFsAudioStreamBuffering:
            return @"Buffering";
            
        case kFsAudioStreamSeeking:
            return @"Seeking";
            
        case kFsAudioStreamPlaying:
            return @"Playing";
            
        case kFsAudioStreamFailed:
            return @"Failed";
            
        case kFsAudioStreamPaused:
            return @"Paused";
            
        case kFSAudioStreamEndOfFile:
            return @"End of File";
            
        case kFsAudioStreamRetryingStarted:
            return @"Retrying Started";
            
        case kFsAudioStreamRetryingSucceeded:
            return @"Retrying Succeeded";
            
        case kFsAudioStreamRetryingFailed:
            return @"Retrying Failed";
            
        case kFsAudioStreamPlaybackCompleted:
            return @"Playback Completed";
            
        case kFsAudioStreamUnknownState:
            return @"FSUnknown";
            
        default:
            return [NSString stringWithFormat:@"Unknown state: %ld", status];
    }
}

- (NSString *)stringForErrorCode:(FSAudioStreamError)errorCode {
    switch (errorCode) {
        case kFsAudioStreamErrorOpen:
            return @"Cannot open the audio stream";
        case kFsAudioStreamErrorStreamParse:
            return @"Cannot read the audio stream";
        case kFsAudioStreamErrorNetwork:
            return @"Network failed: cannot play the audio stream";
        case kFsAudioStreamErrorUnsupportedFormat:
            return @"Unsupported format";
        case kFsAudioStreamErrorStreamBouncing:
            return @"Network failed: cannot get enough data to play";
        default:
            return @"Unknown error occurred";
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

- (void)fsAudioStreamStateDidChange:(NSNotification *)notification {
    if (!(notification.object == self.fsAudio.activeStream)) {
        return;
    }
    
    NSDictionary *dict = [notification userInfo];
    FSAudioStreamState state = [[dict valueForKey:FSAudioStreamNotificationKey_State] intValue];
    
    [self debug:@"[FreeStreamer] %@", [self stringForState:state]];
    
    [self debug:@"_currentIndex = %ld", _currentIndex];
    _currentIndex = [self.queue indexOfURL:self.fsAudio.currentPlaylistItem.url];
    [self debug:@"_currentIndex = %ld", _currentIndex];
    
    _isBuffering = NO;
    _state = state;
    
    switch (state) {
        case kFsAudioStreamRetrievingURL:
            _isBuffering = YES;
            
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerTrackBuffering
                             extraInfo:nil];
            
            break;
            
        case kFsAudioStreamStopped:
            [self stopPlaybackUpdates];
            
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerTrackStopped
                             extraInfo:nil];
            
            break;
            
        case kFsAudioStreamBuffering:
            _isBuffering = YES;
            
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerTrackBuffering
                             extraInfo:nil];
            
            break;
            
        case kFsAudioStreamSeeking:
            _isBuffering = YES;
            
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerTrackBuffering
                             extraInfo:nil];

            break;
            
        case kFsAudioStreamPlaying:
            [self startPlaybackUpdatesWithInterval:self.playbackUpdateTimeInterval];
            
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerTrackPlaying
                             extraInfo:nil];
            
            break;
            
        case kFsAudioStreamFailed:
            [self stopPlaybackUpdates];
            
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerTrackStopped
                             extraInfo:nil];
            
            break;
            
        case kFsAudioStreamPaused:
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerTrackPaused
                             extraInfo:nil];

            break;
            
        case kFsAudioStreamRetryingStarted:
            _isBuffering = YES;
            
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerTrackBuffering
                             extraInfo:nil];
            
            break;
            
        case kFsAudioStreamPlaybackCompleted:
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerTrackChanged
                             extraInfo:nil];
            
            break;

        case kFSAudioStreamEndOfFile:
        case kFsAudioStreamRetryingSucceeded:
        case kFsAudioStreamRetryingFailed:
        case kFsAudioStreamUnknownState:
            
            break;
    }
}

- (void)fsAudioStreamErrorOccurred:(NSNotification *)notification {
    if (!(notification.object == self.fsAudio.activeStream)) {
        return;
    }
    
    NSDictionary *dict = [notification userInfo];
    FSAudioStreamError errorCode = [[dict valueForKey:FSAudioStreamNotificationKey_Error] intValue];
    
    [self debug:@"[FreeStreamer] Error: %@", [self stringForErrorCode:errorCode]];
    
    [self.delegate audioPlayer:self
        uiNeedsRedrawForReason:AGAudioPlayerError
                     extraInfo:@{@"reason": [self stringForErrorCode:errorCode],
                                 @"code": @(errorCode)}];
}

- (void)fsAudioStreamMetaDataAvailable:(NSNotification *)notification {

}

- (FSPlaylistItem *)playlistItemForAudioItem:(id<AGAudioItem>)item {
    FSPlaylistItem *i = FSPlaylistItem.new;
    i.url = item.playbackURL;
    i.title = item.title;
    
    return i;
}

- (NSArray<FSPlaylistItem *>*)fsPlaylist {
    NSMutableArray *arr = NSMutableArray.array;
    
    for (NSUInteger i = 0; i < self.queue.count; i++) {
        id<AGAudioItem> item = [self.queue properQueueForShuffleEnabled:self.shuffle][i];
        
        [arr addObject:[self playlistItemForAudioItem:item]];
    }
    
    return arr;
}

- (CGFloat)volume {
    return self.fsAudio.volume;
}

- (void)setVolume:(CGFloat)volume {
    self.fsAudio.volume = volume;
}

#pragma mark - Queue delegate

- (void)upNextQueueRemovedAllItems:(AGAudioPlayerUpNextQueue *)queue {
    _currentIndex = -1;
    
    [self stop];
}

- (void)upNextQueue:(AGAudioPlayerUpNextQueue *)queue
          addedItem:(id<AGAudioItem>)item
            atIndex:(NSInteger)idx {
    if(idx <= self.currentIndex) {
        _currentIndex++;

        [self.delegate audioPlayer:self
            uiNeedsRedrawForReason:AGAudioPlayerTrackPlaying
                         extraInfo:nil];
    }
    
    [self.fsAudio insertItem:[self playlistItemForAudioItem:item]
                     atIndex:idx];
}

- (void)upNextQueue:(AGAudioPlayerUpNextQueue *)queue
        removedItem:(id<AGAudioItem>)item
          fromIndex:(NSInteger)idx {
    if(idx == self.currentIndex) {
        // FreeStreamer doesn't allow remove the current item
        // so build a new playlist and start at the same index which
        // is now the next track
        [self.fsAudio playFromPlaylist:[self fsPlaylist]
                             itemIndex:idx];
    }
    else {
        [self.fsAudio removeItemAtIndex:idx];
    }
}

-(void)upNextQueue:(AGAudioPlayerUpNextQueue *)queue
         movedItem:(id<AGAudioItem>)item
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

    [self.fsAudio moveItemAtIndex:oldIndex
                          toIndex:newIndex];

    [self debug:@"new currentIndex: %d", self.currentIndex];

    [self.delegate audioPlayer:self
        uiNeedsRedrawForReason:AGAudioPlayerTrackPlaying
                     extraInfo:nil];
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
