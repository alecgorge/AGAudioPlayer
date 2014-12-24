//
//  AGAudioPlayer.m
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#import "AGAudioPlayer.h"

#import "MTRandom.h"

#import "bass.h"
#import "bassflac.h"
#import "bassmix.h"
#import <AVFoundation/AVFoundation.h>

@interface AGAudioPlayer () <AVAudioSessionDelegate> {
    HSTREAM _mainChannel;
}

@property (nonatomic) NSMutableArray *playbackHistory;
@property (nonatomic)

@end

void CALLBACK ChannelEndedCallback(HSYNC handle, DWORD channel, DWORD data, void *user) {
    AGAudioPlayer *player = (__bridge AGAudioPlayer *)(user);
}

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
    [self setupBASS];
}

- (void)dealloc {
    [self teardownBASS];
}

#pragma mark - Playback Control

- (BOOL)isPlaying {
    return BASS_ChannelIsActive(_mainChannel) == BASS_ACTIVE_PLAYING;
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
    BASS_SetConfig(BASS_CONFIG_GVOL_STREAM, volume * 10000.0);
}

- (void)resume {
    BASS_ChannelPlay(_mainChannel, NO);
}

- (void)pause {
    BASS_ChannelPause(_mainChannel);
}

- (void)stop {
    BASS_ChannelStop(_mainChannel);
}

#pragma mark - Playback Order

- (NSInteger)nextIndex

#pragma mark - History management

- (void)setupHistory {
    self.playbackHistory = NSMutableArray.array;
}

- (void)resetHistory {
    [self.playbackHistory removeAllObjects];
}

#pragma mark - BASS management

- (void)setupBASS {
    extern void BASSFLACplugin;
    BASS_PluginLoad(&BASSFLACplugin, 0);
    
    BASS_Init(-1, 44100, 0, NULL, NULL);
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(audioInteruptionOccured:)
                                               name:AVAudioSessionInterruptionNotification
                                             object:nil];
    
    _volume = BASS_GetConfig(BASS_CONFIG_GVOL_STREAM) / 10000.0f;
}

- (void)teardownBASS {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    BASS_Free();
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
