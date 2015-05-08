//
//  AGAudioPlayer.m
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#import "AGAudioPlayer.h"

#import <AVFoundation/AVFoundation.h>

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

@interface FSAudioController ()

@property (nonatomic,assign) NSUInteger currentPlaylistItemIndex;
@property (nonatomic,strong) NSMutableArray *playlistItems;

@end

@interface AGAudioPlayer () <AVAudioSessionDelegate, FSAudioControllerDelegate>

@property BOOL registeredAudioSession;

@property (nonatomic) FSAudioController *freeStreamer;
@property (nonatomic) FSAudioStreamState state;

@property (nonatomic) NSMutableArray *playbackHistory;

@property (nonatomic) NSTimer *playbackUpdateTimer;

@end

@implementation AGAudioPlayer

#pragma mark - Object Lifecycle

- (instancetype)initWithQueue:(AGAudioPlayerUpNextQueue *)queue {
    if (self = [super init]) {
        self.queue = queue;
        
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
    return self.freeStreamer.isPlaying;
}

- (BOOL)isBuffering {
    return self.state == kFsAudioStreamBuffering || self.state == kFsAudioStreamSeeking || self.state == kFsAudioStreamRetrievingURL;
}

- (BOOL)isPlayingFirstItem {
	return self.currentIndex == 0;
}

- (BOOL)isPlayingLastItem {
	return self.currentIndex == self.queue.count - 1;
}

- (void)setShuffle:(BOOL)shuffle {
    _shuffle = shuffle;
    [self replaceNextItemIfNecessary];
}

- (void)setLoopItem:(BOOL)loopItem {
    _loopItem = loopItem;
    [self replaceNextItemIfNecessary];
}

- (void)setLoopQueue:(BOOL)loopQueue {
    _loopQueue = loopQueue;
    [self replaceNextItemIfNecessary];
}

- (void)resume {
    if(self.state == kFsAudioStreamPaused) {
        [self.freeStreamer pause];
    }
}

- (void)pause {
	[self.freeStreamer pause];
}

- (void)stop {
	[self.freeStreamer stop];
}

- (void)forward {
	self.currentIndex = self.nextIndex;
}

- (void)backward {
	if(self.elapsed < 5.0f || self.backwardStyle == AGAudioPlayerBackwardStyleAlwaysPrevious) {
		NSInteger lastIndex = self.previousIndex;
		[self.playbackHistory removeLastObject];
		self.currentIndex = lastIndex;
	}
	else {
		[self seekTo:0];
	}
}

- (void)seekTo:(NSTimeInterval)i {
    FSStreamPosition pos = {0};
    
    pos.position = i / self.duration;
    
	[self.freeStreamer.activeStream seekToPosition:pos];
}

- (void)seekToPercent:(CGFloat)per {
    FSStreamPosition pos = {0};
    
    pos.position = per;
    
    [self.freeStreamer.activeStream seekToPosition:pos];
}

- (NSTimeInterval)duration {
    return self.freeStreamer.activeStream.duration.minute * 60 + self.freeStreamer.activeStream.duration.second;
}

- (NSTimeInterval)elapsed {
    return self.freeStreamer.activeStream.currentTimePlayed.playbackTimeInSeconds;
}

- (CGFloat)percentElapsed {
    return self.freeStreamer.activeStream.currentTimePlayed.position;
}

#pragma mark - Playback Order

- (void)setCurrentIndex:(NSInteger)currentIndex {
	[self.playbackHistory addObject:[AGAudioPlayerHistoryItem.alloc initWithQueue:self.queue
																		 andIndex:self.currentIndex]];
	_currentIndex = currentIndex;
	
	[self stop];
	
	id<AGAudioItem> item = self.currentItem;
	[item loadMetadata:^(id<AGAudioItem> item) {
        [self registerAudioSession];
		[self.freeStreamer addItem:[self playlistItemForAudioItem:item]];
        [self.freeStreamer playItemAtIndex:self.freeStreamer.countOfItems - 1];
        [self replaceNextItemIfNecessary];
	}];
    
    [self.nextItem loadMetadata:^(id<AGAudioItem> item) {
        
    }];
}

- (void)playItemAtIndex:(NSUInteger)idx {
    self.currentIndex = idx;
}

- (id<AGAudioItem>)currentItem {
    if(self.currentIndex >= self.queue.count) {
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
    return [NSString stringWithFormat:@"%@<%p>:\n    state: %@\n    shuffle: %d, loop: %d\n    currentItem (index: %d): %@\n    playback: %.2f/%.2f (%.2f%%)", NSStringFromClass(self.class), self, [self stringForState:self.state], self.shuffle, self.loopItem || self.loopQueue, self.currentIndex, self.currentItem, self.elapsed, self.duration, self.percentElapsed * 100.0f];
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
    FSStreamConfiguration *config = FSStreamConfiguration.new;
    config.maxPrebufferedByteCount = 1024 * 1024 * 10;
    
    self.freeStreamer = FSAudioController.new;
    self.freeStreamer.enableDebugOutput = YES;
    self.freeStreamer.delegate = self;
    
    __weak typeof(self) wself = self;
    
    [self.freeStreamer setOnFailure:^(FSAudioStreamError error, NSString *errorMessage) {
        [wself debug:@"FreeStreamer: Error: %@. %@", [wself stringForErrorCode:error], errorMessage];
        
        [wself.delegate audioPlayer:wself
            uiNeedsRedrawForReason:AGAudioPlayerError
                         extraInfo:@{@"error": [wself stringForErrorCode:error]}];
    }];
    
    [self.freeStreamer setOnStateChange:^(FSAudioStreamState state) {
        [wself debug:@"FreeStreamer: Old state: %@. New state: %@", [wself stringForState: wself.state], [wself stringForState:state]];
        
        [wself willChangeValueForKey:@"state"];
        wself.state = state;
        [wself didChangeValueForKey:@"state"];
        
        [wself didChangeState:wself.state];
    }];
    
    [self.freeStreamer setOnMetaDataAvailable:^(NSDictionary *meta) {
        [wself debug:@"FreeStreamer: Metadata Available: %@", meta];
    }];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(audioInteruptionOccured:)
                                               name:AVAudioSessionInterruptionNotification
                                             object:nil];
}

- (void)teardownFreeStreamer {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (NSString *)stringForState:(FSAudioStreamState)status {
    switch (status) {
        case kFsAudioStreamRetrievingURL:
            return @"Retrieving URL";
        case kFsAudioStreamStopped:
            return @"Stopped";
        case kFsAudioStreamBuffering:
            return @"Buffering";
        case kFsAudioStreamPlaying:
            return @"Playing";
        case kFsAudioStreamPaused:
            return @"Paused";
        case kFsAudioStreamSeeking:
            return @"Seeking";
        case kFSAudioStreamEndOfFile:
            return @"Got Stream EOF";
        case kFsAudioStreamFailed:
            return @"Stream Failed";
        case kFsAudioStreamRetryingStarted:
            return @"Stream Retrying: Started";
        case kFsAudioStreamRetryingSucceeded:
            return @"Stream Retrying: Success";
        case kFsAudioStreamRetryingFailed:
            return @"Stream Retrying: Failed";
        case kFsAudioStreamPlaybackCompleted:
            return @"Playback Complete";
        case kFsAudioStreamUnknownState:
            return @"Unknown!?";
    }
}

- (NSString *)stringForErrorCode:(FSAudioStreamError)status {
    switch (status) {
        case kFsAudioStreamErrorNone:
            return @"No Error";
        case kFsAudioStreamErrorOpen:
            return @"Error: open";
        case kFsAudioStreamErrorStreamParse:
            return @"Error: stream parse";
        case kFsAudioStreamErrorNetwork:
            return @"Error: network";
        case kFsAudioStreamErrorUnsupportedFormat:
            return @"Error: unsupported format";
        case kFsAudioStreamErrorStreamBouncing:
            return @"Error: stream bouncing";
    }
}

- (void)replaceNextItemIfNecessary {
    id<AGAudioItem> item = self.nextItem;

    if(!item) {
        [self debug:@"there is no next item"];
        return;
    }

    [item loadMetadata:^(id<AGAudioItem> item) {
        [self debug:@"preloaded next metadata"];
        
        FSPlaylistItem *pitem = [self playlistItemForAudioItem: item];
        
        if(!self.freeStreamer.hasNextItem) {
            [self.freeStreamer addItem:pitem];
        }
        else {
            FSPlaylistItem *apitem = self.freeStreamer.playlistItems[self.freeStreamer.currentPlaylistItemIndex + 1];
            if(![apitem.url isEqual:item.playbackURL]) {
                [self.freeStreamer replaceItemAtIndex:self.freeStreamer.currentPlaylistItemIndex + 1
                                             withItem:pitem];
            }
        }
    }];
}

- (FSPlaylistItem *)playlistItemForAudioItem:(id<AGAudioItem>) item {
    FSPlaylistItem *i = FSPlaylistItem.new;
    
    i.title = item.displayText;
    i.url = item.playbackURL;
    
    return i;
}

- (void)debug:(NSString *)str, ... {
    va_list args;
    va_start(args, str);
    NSString *s = [NSString.alloc initWithFormat:str
                                       arguments:args];
    NSLog(@"[AGAudioPlayer] %@", s);
    va_end(args);
}

#pragma mark - FSAudioControllerDelegate

- (void)audioController:(FSAudioController *)audioController
preloadStartedForStream:(FSAudioStream *)stream {
    [self debug:@"FreeStreamer: preloadStartedForStream: %@", stream];
}

- (BOOL)audioController:(FSAudioController *)audioController
allowPreloadingForStream:(FSAudioStream *)stream {
    return YES;
}

- (void)didChangeState:(FSAudioStreamState)state {
    _currentIndex = [self.queue indexOfURL:self.freeStreamer.currentPlaylistItem.url];
    
    switch (state) {
        case kFsAudioStreamRetrievingURL: {
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerTrackBuffering
                             extraInfo:nil];
            
            break;
        }
        case kFsAudioStreamStopped: {
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerTrackStopped
                             extraInfo:nil];
            
            [self stopPlaybackUpdates];

            break;
        }
        case kFsAudioStreamBuffering: {
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerTrackBuffering
                             extraInfo:nil];
            
            break;
        }
        case kFsAudioStreamPlaying: {
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerTrackPlaying
                             extraInfo:nil];
            
            [self startPlaybackUpdatesWithInterval:self.playbackUpdateTimeInterval];

            break;
        }
        case kFsAudioStreamPaused: {
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerTrackPaused
                             extraInfo:nil];
            
            [self stopPlaybackUpdates];

            break;
        }
        case kFsAudioStreamSeeking: {
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerTrackBuffering
                             extraInfo:nil];

            break;
        }
        case kFSAudioStreamEndOfFile: {
//            [self prepareNextItem];
            break;
        }
        case kFsAudioStreamFailed: {
            break;
        }
        case kFsAudioStreamRetryingStarted: {
            break;
        }
        case kFsAudioStreamRetryingSucceeded: {
            break;
        }
        case kFsAudioStreamRetryingFailed: {
            break;
        }
        case kFsAudioStreamPlaybackCompleted: {
            break;
        }
        case kFsAudioStreamUnknownState: {
            break;
        }
    }
}

#pragma mark - Interruption Handling

- (void)registerAudioSession {
    if (!self.registeredAudioSession) {
//        [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback
//                                             error:nil];
//        
//        [AVAudioSession.sharedInstance setActive:YES
//                                           error:nil];
        
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(audioRouteChanged:)
                                                   name:AVAudioSessionRouteChangeNotification
                                                 object:nil];
        
        self.registeredAudioSession = YES;
        
//        [NSNotificationCenter.defaultCenter addObserver:self
//                                               selector:@selector(audioInteruptionOccured:)
//                                                   name:AVAudioSessionInterruptionNotification
//                                                 object:nil];
    }
}

- (void)audioRouteChanged:(NSNotification *)notification {
    NSNumber *reason = notification.userInfo[AVAudioSessionRouteChangeReasonKey];
    
    if(reason.integerValue == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        [self pause];
    }
}

- (void)audioInteruptionOccured:(NSNotification *)notification {
    NSDictionary *interruptionDictionary = notification.userInfo;
    AVAudioSessionInterruptionType interruptionType = [interruptionDictionary[AVAudioSessionInterruptionTypeKey] integerValue];
    
    switch (interruptionType) {
        case AVAudioSessionInterruptionTypeBegan: {
            [self debug:@"AVAudioSession: interruption began"];
            
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
            
            BOOL resume = options == AVAudioSessionInterruptionOptionShouldResume;
            
            [self debug:@"AVAudioSession: interruption ended, should resume: %@", resume ? @"YES" : @"NO"];
            
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
}

@end
