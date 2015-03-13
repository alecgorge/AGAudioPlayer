//
//  AGAudioPlayerUpNextQueue.h
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#import <UIKit/UIKit.h>
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
          addedItem:(AGAudioItem *)item
            atIndex:(NSInteger)idx;

- (void)upNextQueue:(AGAudioPlayerUpNextQueue *)queue
        removedItem:(AGAudioItem *)item
          fromIndex:(NSInteger)idx;

- (void)upNextQueue:(AGAudioPlayerUpNextQueue *)queue
        swappedItem:(AGAudioItem *)item
            atIndex:(NSInteger)oldIndex
           withItem:(AGAudioItem *)item2
            atIndex:(NSInteger)oldIndex2;

- (void)upNextQueue:(AGAudioPlayerUpNextQueue *)queue
        updatedItem:(AGAudioItem *)item
            atIndex:(NSInteger)oldIndex
        withNewItem:(AGAudioItem *)item;

- (void)upNextQueueRemovedAllItems:(AGAudioPlayerUpNextQueue *)queue;

@end

@interface AGAudioPlayerUpNextQueue : NSObject

- (instancetype)initWithItems:(NSArray *)items;

@property (nonatomic, weak) id<AGAudioPlayerUpNextQueueDelegate> delegate;

@property (nonatomic, readonly) NSInteger count;

@property (nonatomic, readonly) NSArray *queue;
@property (nonatomic, readonly) NSArray *shuffledQueue;

- (void)appendItem:(AGAudioItem *)item;
- (void)appendItems:(NSArray *)items;

- (void)prependItem:(AGAudioItem *)item;
- (void)prependItems:(NSArray *)items;

- (void)moveItem:(AGAudioItem *)item
         toIndex:(NSInteger)to;

- (void)moveItemAtIndex:(NSInteger)from
                toIndex:(NSInteger)to;

- (void)clear;

- (void)removeItem:(AGAudioItem *)item;
- (void)removeItemAtIndex:(NSInteger)indx;

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx;

- (AGAudioItem *)shuffledItemAtIndex:(NSUInteger)idx;
- (AGAudioItem *)unshuffledItemAtIndex:(NSUInteger)idx;

- (NSArray *)properQueueForShuffleEnabled:(BOOL)shuffleEnabled;

@end
