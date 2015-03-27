//
//  AGScrubber.m
//  AGAudioPlayer
//
//  Created by Alec Gorge on 3/15/15.
//  Copyright (c) 2015 Alec Gorge. All rights reserved.
//

#import "AGScrubber.h"

@implementation AGScrubber

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		[self setup];
	}
	
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		[self setup];
	}
	return self;
}

- (void)setup {
//	self.minimumValueImage = 
}

- (CGRect)minimumValueImageRectForBounds:(CGRect)bounds {
	CGRect rect = [super minimumValueImageRectForBounds:bounds];
	
	NSLog(@"minimumValueImageRectForBounds: bounds: %@. rect: %@", NSStringFromCGRect(bounds), NSStringFromCGRect(rect));
	
	return rect;
}

- (CGRect)maximumValueImageRectForBounds:(CGRect)bounds {
	CGRect rect = [super maximumValueImageRectForBounds:bounds];
	
	NSLog(@"maximumValueImageRectForBounds: bounds: %@. rect: %@", NSStringFromCGRect(bounds), NSStringFromCGRect(rect));
	
	return rect;
}

- (CGRect)trackRectForBounds:(CGRect)bounds {
	CGRect rect = [super trackRectForBounds:bounds];
	
	NSLog(@"trackRectForBounds: bounds: %@. rect: %@", NSStringFromCGRect(bounds), NSStringFromCGRect(rect));
	
	return rect;

	CGRect newBounds = [super trackRectForBounds:bounds];
	
	newBounds.size.height = 8.0f;
	
	return newBounds;
}

- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)inrect value:(float)value {
	CGRect rect = [super thumbRectForBounds:bounds
								  trackRect:inrect
									  value:value];
	
	NSLog(@"thumbRectForBounds: bounds: %@. rect: %@", NSStringFromCGRect(bounds), NSStringFromCGRect(rect));
	
	return rect;

	CGRect newBounds = [super thumbRectForBounds:bounds
									   trackRect:inrect
										   value:value];
	
	newBounds.size.height = 16.0f;
	newBounds.size.width = 2.0f;
	
	return newBounds;
}

@end
