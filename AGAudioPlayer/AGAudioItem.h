//
//  AGAudioItem.h
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AGAudioItem : NSObject<NSCoding>

@property (nonatomic) NSInteger trackNumber;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *artist;
@property (nonatomic) NSString *album;

@property (nonatomic) NSTimeInterval duration;

@property (nonatomic) NSString *displayText;
@property (nonatomic) NSString *displaySubtext;

@property (nonatomic) NSURL *albumArt;
@property (nonatomic) NSURL *playbackURL;
@property (nonatomic) NSDictionary *playbackRequestHTTPHeaders;

@property (nonatomic) BOOL metadataLoaded;

- (void)loadMetadata:(void (^)(AGAudioItem *))metadataCallback;

- (void)shareText:(void(^)(NSString *))stringBuilt;
- (void)shareURL:(void(^)(NSURL *))urlFound;

- (void)shareURLWithTime:(NSTimeInterval)shareTime
				callback:(void(^)(NSURL *))urlFound;

@end
