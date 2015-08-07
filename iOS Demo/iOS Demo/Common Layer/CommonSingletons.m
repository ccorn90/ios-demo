//
//  CommonSingletons.m
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

#import "CommonSingletons.h"
#import "DemoNetworkManager.h"

@interface CommonSingletons ()

@property (nonatomic, retain) id<AbstractNetworkManager> networkManager;

@end



@implementation CommonSingletons
@synthesize networkManager = _networkManager;

#pragma mark - Construct CommonSingletons:
-(CommonSingletons*) init {
    if(self = [super init]) {
        self.networkManager = [[DemoNetworkManager alloc] init];
        LogI(@"Constructed CommonSingletons.");
    }
    return self;
}


#pragma mark - Implementing CommonSingletonsInterface:
// -(id<NetworkManagerInterface>) networkManager;  // implemented via private @property in CommonSingletons ()



@end
