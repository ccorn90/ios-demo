//
//  Singletons.m
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

#import "Singletons.h"
#import <UIKit/UIKit.h>

#import "CommonSingletons.h"
#import "CommonLayerDemo.h"
#import "NKNetworkManager.h"
#import "NKURLConnectionBridge.h"

// TASK: Should this be __weak?  I dunno yet... it seems like it would be
// held weakly by the system, so we'd need to retain it.  But then, it
// also seems like somewhere in the system might hold it strongly, too.  Hmm.
Singletons* __globalDelegateRef = nil;

@interface Singletons ()

@property (nonatomic, retain) CommonSingletons* commonSingletons;
@property (nonatomic, retain) CommonLayerDemo*  demo;

@end

@implementation Singletons
#pragma mark - Synthesize all the singletons
@synthesize commonSingletons = _commonSingletons;

@synthesize window = _window;

#pragma mark - Static method to get the delegate
+(Singletons*) get {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __globalDelegateRef = (Singletons*)[[UIApplication sharedApplication] delegate];
    });
    
#ifndef RELEASE
    if(__globalDelegateRef == nil) {
        // This is a major assertion failure.
        LogWTF(@"No singletons pointer anymore!  Was it declared __weak?  Anyway, expect a crash soon.");
    }
#endif
    
    return __globalDelegateRef;
}

#pragma mark - The UIApplicationDelegate methods
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    /* The application has launched! */
    /* First thing, set up the CommonSingletons - this holds all the base services we rely on */
    self.commonSingletons = [[CommonSingletons alloc] init];
    
    /* Set up managers, etc */
    // None yet
    
    /* Set up window and main view heirarchy */
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // This makes the window visible and actually initializes the UI:
    // TODO: Eventually we'll want to make a view heirarchy that actually does something.
    [self.window setRootViewController:[[UIViewController alloc] init]];
    [self.window makeKeyAndVisible];
    
    
    // Start the demo.  We'll do this asynchronously after 100ms so the main thread can continue right now.
    /*self.demo = [[CommonLayerDemo alloc] init];
    dispatch_after(0.1, dispatch_get_main_queue(), ^{
        [self.demo start];
    });*/
    
    static NKNetworkManager* networkMgr = nil;
    networkMgr = [[NKNetworkManager alloc] initWithConnectionBridge:[[NKDefaultURLConnectionBridge alloc] init]];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        networkMgr = nil;
    
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            networkMgr = [[NKNetworkManager alloc] initWithConnectionBridge:[[NKDefaultURLConnectionBridge alloc] init]];
            NKNetworkManager* networkMgr2 = [[NKNetworkManager alloc] initWithConnectionBridge:[[NKDefaultURLConnectionBridge alloc] init]];
            
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                networkMgr = nil;
            });
        });
    });
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /* APPLE'S NOTES: */
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /* APPLE'S NOTES: */
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /* APPLE'S NOTES: */
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /* APPLE'S NOTES: */
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    /* APPLE'S NOTES: */
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
}



#pragma mark - As CommonSingletonsInterface
-(id<AbstractNetworkManager>) networkManager {
    return self.commonSingletons.networkManager;
}




@end
