//
//  AGAudioItemCollection.h
//  AGAudioPlayer
//
//  Created by Alec Gorge on 3/15/15.
//  Copyright (c) 2015 Alec Gorge. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AGCachable.h"

@protocol AGAudioItemCollection <AGCachable>

@property (nonatomic) NSString *displayText;
@property (nonatomic) NSString *displaySubtext;
@property (nonatomic) NSURL *albumArt;

@property (nonatomic) NSArray *items;

@end

@interface AGAudioItemCollectionBase : NSObject<AGAudioItemCollection>

// an array of id<AGAudioObjects>
- (instancetype)initWithItems:(NSArray *)items;

@end
