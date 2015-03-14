//
//  AGAudioPlayer.m
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#import "AGAudioPlayer.h"

#import <AVFoundation/AVFoundation.h>
#import <OrigamiEngine/ORGMEngine.h>

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

@interface AGAudioPlayer () <AVAudioSessionDelegate, ORGMEngineDelegate>

@property (nonatomic) ORGMEngine *oriagmi;
@property (nonatomic) NSMutableArray *playbackHistory;

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
    [self setupOrigami];
}

- (void)dealloc {
    [self teardownOrigami];
}

#pragma mark - Playback Control

- (BOOL)isPlaying {
    return self.oriagmi.currentState == ORGMEngineStatePlaying;
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
	[self.oriagmi resume];
}

- (void)pause {
	[self.oriagmi pause];
}

- (void)stop {
	[self.oriagmi stop];
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
	[self.oriagmi seekToTime:i];
}

- (void)seekToPercent:(CGFloat)per {
	[self seekTo:per * self.duration];
}

#pragma mark - Playback Order

- (void)setCurrentIndex:(NSInteger)currentIndex {
	[self.playbackHistory addObject:[AGAudioPlayerHistoryItem.alloc initWithQueue:self.queue
																		 andIndex:self.currentIndex]];
	_currentIndex = currentIndex;
	
	[self stop];
	
	AGAudioItem *item = self.currentItem;
	[item loadMetadata:^(AGAudioItem *item) {
		[self.oriagmi playUrl:item.playbackURL];
	}];
    
    // preload metadata
    [self prepareNextItem];
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

#pragma mark - History management

- (void)setupHistory {
    self.playbackHistory = NSMutableArray.array;
}

- (void)resetHistory {
    [self.playbackHistory removeAllObjects];
}

#pragma mark - Origami Engine management

- (void)setupOrigami {
    self.oriagmi = ORGMEngine.alloc.init;
    self.oriagmi.delegate = self;
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(audioInteruptionOccured:)
                                               name:AVAudioSessionInterruptionNotification
                                             object:nil];
}

- (void)teardownOrigami {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)prepareNextItem {
	AGAudioItem *item = self.nextItem;
    [item loadMetadata:^(AGAudioItem *item) {
        // preloaded metadata
    }];
}

#pragma mark - ORGMEngineDelegate

- (NSURL *)engineExpectsNextUrl:(ORGMEngine *)engine {
    [self debug: @"Engine: engineExpectsNextUrl"];
    
    AGAudioItem *next = self.nextItem;
    [self incrementIndex];
    
    return next.playbackURL;
}

- (void)debug:(NSString *)str {
    NSLog(@"[AGAudioPlayer] %@", str);
}

- (void)engine:(ORGMEngine *)engine
didChangeState:(ORGMEngineState)state {
    switch (state) {
        case ORGMEngineStateStopped: {
            [self debug:@"Engine: stopped"];
            
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerTrackStopped
                             extraInfo:nil];
            
            break;
        }
        case ORGMEngineStatePaused: {
            [self debug:@"Engine: paused"];
            
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerTrackPaused
                             extraInfo:nil];
            
            break;
        }
        case ORGMEngineStatePlaying: {
            [self debug:@"Engine: playing"];
            
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerTrackPlaying
                             extraInfo:nil];
            
            break;
        }
        case ORGMEngineStateError:
            [self debug:[NSString stringWithFormat:@"Engine: error: %@", self.oriagmi.currentError]];
            
            
            [self.delegate audioPlayer:self
                uiNeedsRedrawForReason:AGAudioPlayerError
                             extraInfo:@{@"error": self.oriagmi.currentError}];
            
            break;
    }
}

#pragma mark - Interruption Handling

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
            
            [self debug:[NSString stringWithFormat:@"AVAudioSession: interruption ended, should resume: %@", resume ? @"YES" : @"NO"]];
            
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
