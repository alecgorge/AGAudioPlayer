//
//  AGAudioItem.m
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#import "AGAudioItem.h"

@implementation AGAudioItem

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.trackNumber	= [aDecoder decodeIntegerForKey:@"trackNumber"];
		self.title			= [aDecoder decodeObjectForKey:@"title"];
		self.artist			= [aDecoder decodeObjectForKey:@"artist"];
		self.album			= [aDecoder decodeObjectForKey:@"album"];
		self.duration		= [aDecoder decodeDoubleForKey:@"duration"];
		self.displayText	= [aDecoder decodeObjectForKey:@"displayText"];
		self.displaySubtext = [aDecoder decodeObjectForKey:@"displaySubtext"];
		self.albumArt		= [aDecoder decodeObjectForKey:@"albumArt"];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInteger:self.trackNumber
				   forKey:@"trackNumber"];
	
	[aCoder encodeObject:self.title
				  forKey:@"title"];
	
	[aCoder encodeObject:self.artist
				  forKey:@"artist"];
	
	[aCoder encodeObject:self.album
				  forKey:@"album"];
	
	[aCoder encodeDouble:self.duration
				  forKey:@"duration"];
	
	[aCoder encodeObject:self.displayText
				  forKey:@"displayText"];
	
	[aCoder encodeObject:self.displaySubtext
				  forKey:@"displaySubtext"];
	
	[aCoder encodeObject:self.albumArt
				  forKey:@"albumArt"];
}

- (BOOL)metadataLoaded {
	return YES;
}

- (void)loadMetadata:(void (^)(AGAudioItem *))metadataCallback {
	NSAssert(NO, @"This method must be overriden");
}

- (void)shareText:(void (^)(NSString *))stringBuilt {
	NSAssert(NO, @"This method must be overriden");
}

- (void)shareURL:(void (^)(NSURL *))urlFound {
	NSAssert(NO, @"This method must be overriden");
}

- (void)shareURLWithTime:(NSTimeInterval)shareTime
				callback:(void (^)(NSURL *))urlFound {
	NSAssert(NO, @"This method must be overriden");
}

@end
