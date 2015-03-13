//
//  AGAudioPlayer.m
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#import "AGAudioPlayer.h"

#import "MTRandom.h"

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

@interface AGAudioPlayer () <AVAudioSessionDelegate>

@property (nonatomic) ORGMEngine *oriagmi;
@property (nonatomic) NSMutableArray *playbackHistory;

@end

@implementation AGAudioPlayer

#pragma mark - Object Lifecycle

- (instancetype)initWithExplicitQueue:(AGAudioPlayerUpNextQueue *)ex
                     andImplicitQueue:(AGAudioPlayerUpNextQueue *)im {
    if (self = [super init]) {
        self.explicitUpcomingQueue = ex;
        self.implicitUpcomingQueue = im;
        
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

- (void)setVolume:(CGFloat)volume {
    _volume = volume;
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
	if(self.elapsed < 5.0f) {
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
	[self.playbackHistory addObject:[AGAudioPlayerHistoryItem.alloc initWithQueue:self.currentQueue
																		 andIndex:self.currentIndex]];
	_currentIndex = currentIndex;
	
	[self stop];
	
	AGAudioItem *item = self.currentItem;
	[item loadMetadata:^(AGAudioItem *item) {
		[self.oriagmi setNextUrl:<#(NSURL *)#> withDataFlush:<#(BOOL)#>]
	}];
}

- (AGAudioPlayerUpNextQueue *)currentQueue {
	
}

- (AGAudioPlayerUpNextQueue *)nextQueue {
	// looping a single track
	if (self.loopItem) {
		return self.currentQueue;
	}
	
	// find the "other" queue
	AGAudioPlayerUpNextQueue *altQueue = nil;
	if(self.currentQueue == self.explicitUpcomingQueue) {
		altQueue = self.implicitUpcomingQueue;
	}
	else {
		altQueue = self.explicitUpcomingQueue;
	}
	
	// last song in the current queue
	if (self.currentIndex == self.currentQueue.count) {
		// there isn't anything in the next queue
		if(altQueue.count == 0) {
			// start the current queue from the beginning
			if(self.loopQueue) {
				return self.currentQueue;
			}
			// reached the end of all tracks, accross both queues
			else {
				return nil;
			}
		}
		// play the first track in the next queue
		else {
			return altQueue;
		}
	}
	// there are still songs in the current queue
	else {
		return self.currentQueue;
	}
}

- (NSInteger)nextIndex {
	// looping a single track
	if (self.loopItem) {
		return self.currentIndex;
	}
	
	// last song in the current queue
	if (self.currentIndex == self.currentQueue.count) {
		// there isn't anything in the next queue
		if(self.nextQueue.count == 0) {
			// start the current queue from the beginning
			if(self.loopQueue) {
				return 0;
			}
			// reached the end of all tracks, accross both queues
			else {
				return NSNotFound;
			}
		}
		// play the first track in the next queue
		else {
			return 0;
		}
	}
	// there are still songs in the current queue
	else {
		return self.currentIndex + 1;
	}
}

- (AGAudioItem *)nextItem {
	return [self.nextQueue properQueueForShuffleEnabled:self.shuffle][self.nextIndex];
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
	_currentQueue = self.nextQueue;
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
}

- (void)teardownOrigami {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)enqueueNextItem {
	AGAudioItem *item = self.nextItem;
	[item audioURL:^(NSURL *url, NSArray *headers) {
		NSString *abs_url = url.absoluteString;
		
		if (headers.count > 0) {
			abs_url = [NSString stringWithFormat:@"%@\r\n%@", url, [headers componentsJoinedByString:@"\r\n"]];
		}
		
		const char *c_url = [abs_url cStringUsingEncoding:NSUTF8StringEncoding];
		DWORD flags = BASS_STREAM_STATUS | BASS_STREAM_DECODE;
		_nextChannel = BASS_StreamCreateURL(c_url, 0, flags, StreamDownloadProgressCallback, (void *)CFBridgingRetain(item));
		
		BASS_Mixer_StreamAddChannel(_mixer, _nextChannel, BASS_STREAM_AUTOFREE | BASS_MIXER_NORAMPIN);
	}];
}

#pragma mark - Interruption Handling

- (void)audioInteruptionOccured:(NSNotification *)notification {
    NSDictionary *interruptionDictionary = notification.userInfo;
    AVAudioSessionInterruptionType interruptionType = [interruptionDictionary[AVAudioSessionInterruptionTypeKey] integerValue];
    
    switch (interruptionType) {
        case AVAudioSessionInterruptionTypeBegan: {
            
//            if ([self.delegate respondsToSelector:@selector(playerBeginInterruption:)]) {
//                [self.delegate playerBeginInterruption:self];
//            }
        }
            
            break;
        case AVAudioSessionInterruptionTypeEnded: {
            AVAudioSessionInterruptionOptions options = [interruptionDictionary[AVAudioSessionInterruptionOptionKey] integerValue];
            
//            if ([self.delegate respondsToSelector:@selector(playerEndInterruption:shouldResume:)]) {
//                [self.delegate playerEndInterruption:self
//                                        shouldResume:options == AVAudioSessionInterruptionOptionShouldResume];
//            }
        }
            break;
            
        default:
            break;
    }
}

@end
