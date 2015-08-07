//
//  CommonSingletons.h
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

#import <Foundation/Foundation.h>
#import "CommonSingletonsInterface.h"
#import "Logging.h"

@interface CommonSingletons : NSObject <CommonSingletonsInterface>

#pragma mark - Construct CommonSingletons:
-(CommonSingletons*) init;


#pragma mark - Implementing CommonSingletonsInterface:
-(id<AbstractNetworkManager>) networkManager;

@end
