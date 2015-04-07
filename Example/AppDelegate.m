//
//  AppDelegate.m
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#import "AppDelegate.h"

#import "AGAudioPlayer.h"
#import "AGAudioPlayerViewController.h"
#import "AGAudioPlayerUpNextQueue.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	UISlider.appearance.tintColor = UIColor.greenColor;
	
	self.window = [UIWindow.alloc initWithFrame:UIScreen.mainScreen.bounds];
	
	AGAudioPlayerUpNextQueue *queue = [AGAudioPlayerUpNextQueue.alloc initWithItems:@[]];
	AGAudioPlayer *player = [AGAudioPlayer.alloc initWithQueue:queue];
	
	AGAudioPlayerViewController *vc = [AGAudioPlayerViewController.alloc initWithAudioPlayer:player];
	vc.foregroundColor = UIColor.whiteColor;
	vc.backgroundColor = [UIColor colorWithRed:0.0/255.0 green:128.0/255.0 blue:95.0/255.0 alpha:1.0];
	vc.lightForegroundColor = UIColor.whiteColor;
	vc.darkForegroundColor = [UIColor colorWithRed:0.0/255.0 green:99.0/255.0 blue:74.0/255.0 alpha:0.8];
	vc.tintColor = UIColor.whiteColor;
	
	UINavigationController *nav = [UINavigationController.alloc initWithRootViewController:vc];
	
	self.window.rootViewController = nav;
	
	[self.window makeKeyAndVisible];
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
