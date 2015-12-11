//
//  AGAudioPlayerUpNextQueue.h
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import <Foundation/NSEnumerator.h>

#import "AGAudioItem.h"

typedef NS_ENUM(NSInteger, AGAudioPlayerUpNextQueueChanged) {
    AGAudioPlayerUpNextQueueAddedItem,
    AGAudioPlayerUpNextQueueRemovedItem,
    AGAudioPlayerUpNextQueueRemovedAllItems,
    AGAudioPlayerUpNextQueueSwappedItems,
    AGAudioPlayerUpNextQueueChangedItem,
};

@class AGAudioPlayerUpNextQueue;

@protocol AGAudioPlayerUpNextQueueDelegate <NSObject>

@optional

- (void)upNextQueueChanged:(AGAudioPlayerUpNextQueueChanged)changeType;

- (void)upNextQueue:(AGAudioPlayerUpNextQueue *)queue
          addedItem:(id<AGAudioItem>)item
            atIndex:(NSInteger)idx;

- (void)upNextQueue:(AGAudioPlayerUpNextQueue *)queue
        removedItem:(id<AGAudioItem>)item
          fromIndex:(NSInteger)idx;

- (void)upNextQueue:(AGAudioPlayerUpNextQueue *)queue
          movedItem:(id<AGAudioItem>)item
          fromIndex:(NSInteger)oldIndex
            toIndex:(NSInteger)newIndex;

- (void)upNextQueueRemovedAllItems:(AGAudioPlayerUpNextQueue *)queue;

@end

@interface AGAudioPlayerUpNextQueue : NSObject<NSCoding>

- (instancetype)initWithItems:(NSArray *)items;

@property (nonatomic, weak) id<AGAudioPlayerUpNextQueueDelegate> delegate;

@property (nonatomic, readonly) NSInteger count;

@property (nonatomic, readonly) NSArray *queue;
@property (nonatomic, readonly) NSArray *shuffledQueue;

- (void)appendItem:(id<AGAudioItem>)item;
- (void)appendItems:(NSArray *)items;

- (void)prependItem:(id<AGAudioItem>)item;
- (void)prependItems:(NSArray *)items;

- (void)insertItem:(id<AGAudioItem>)item atIndex: (NSUInteger)idx;

- (void)moveItem:(id<AGAudioItem>)item
         toIndex:(NSInteger)to;

- (void)moveItemAtIndex:(NSInteger)from
                toIndex:(NSInteger)to;

- (void)clear;

- (void)clearAndReplaceWithItems:(NSArray *)items;

- (void)removeItem:(id<AGAudioItem>)item;
- (void)removeItemAtIndex:(NSInteger)indx;

- (id)objectAtIndexedSubscript:(NSUInteger)idx;

- (id<AGAudioItem>)shuffledItemAtIndex:(NSUInteger)idx;
- (id<AGAudioItem>)unshuffledItemAtIndex:(NSUInteger)idx;

- (NSArray *)properQueueForShuffleEnabled:(BOOL)shuffleEnabled;

- (NSUInteger)indexOfURL:(NSURL *)url;

@end
