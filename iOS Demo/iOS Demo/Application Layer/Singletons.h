//
//  Singletons.h
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

// THIS IS THE UIAPPLICATIONDELEGATE INSTANCE!!!!!!!

/** Holds all the managers, coordinators, and views - this is the only true singleton in the app. */

// For the UIApplicationDelegate protocol
#import <UIKit/UIApplication.h>

// For the CommonSingletonsInterface protocol - this Singletons object acts like
// a CommonSingletons object (it actually owns one inside and exposes the elements).
#import "CommonSingletonsInterface.h"

// A macro to make things more readable.  Now you can just
// write SINGLETONS.whateverThing to get any of the
// singletons held by the global instance.
#define SINGLETONS ([Singletons get])

@interface Singletons : UIResponder <UIApplicationDelegate, CommonSingletonsInterface>

#pragma mark - Static method to get the global instance:
+(Singletons*) get;

#pragma mark - UI Components:
@property (strong, nonatomic) UIWindow* window;

#pragma mark - As CommonSingletonsInterface
-(id<AbstractNetworkManager>) networkManager;

@end