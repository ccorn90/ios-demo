//
//  CommonSingletonsInterface.h
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

/** Defines a protocol that includes getter methods for all singletons
 in the common layer.  The idea is that either an instance of
 CommonSingletons will be used OR a singleton instance in the
 application layer (the UIApplicationDelegate is a good choice)
 will implement this protocol and instantiate a CommonSingletons of its own.
 */

#import "AbstractNetworkManager.h"

@protocol CommonSingletonsInterface <NSObject>
@required

-(id<AbstractNetworkManager>) networkManager;

@end