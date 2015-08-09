//
//  CommonLayerDemo.m
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

#import "CommonLayerDemo.h"
#import "Logging.h"
#import "Singletons.h"
#import "DemoNetworkManager.h"
#import "NetworkManagerStatistics.h"

@interface CommonLayerDemo () <NetworkManagerDelegate>

@property (nonatomic, retain) NSTimer* timer;

@end

@implementation CommonLayerDemo

-(void) start {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(timerFired) userInfo:nil repeats:YES];
    
    NSString* str = @"http://concept.io";
    [SINGLETONS.networkManager get:str delegate:self context:str];
}


// This gets called repeatedly.  We'll just use it to log the current network stats:
-(void) timerFired {
    NetworkManagerStatistics* stats = [(DemoNetworkManager*)SINGLETONS.networkManager currentStatistics];
    
    [stats printAll];
}





// Called when a call is started.  This will happen immediately when you call
// a method on NetworkManager that falls down to the startNetworkCall method.
// It will happen in the same flow (synchronously) with your call into
// startNetworkCall, and it will happen only if there are no errors starting
// the call.  If there is an error preflighting the call, you'll get the onError
// callback instead.
-(void) networkManager:(id<AbstractNetworkManager>)networkManager didStartCall:(id)context {
    
}

// Called when the network manager loads the header for the remote resource.
// This allows the delegate to choose to cancel the call if one of the the
// HTTP headers is not as expected, and it gives the Content-Length, too.
-(void) networkManager:(id<AbstractNetworkManager>)networkManager didLoadHeader:(id)context
                  size:(int)size headers:(NSDictionary*)allHeaderFields {
    
}

// Success!  This will be followed by didFinish.
-(void) networkManager:(id<AbstractNetworkManager>)networkManager didSucceed:(id)context data:(NSData*)data {
    LogD(@"demo", @"got response of %d bytes to %@", data.length, context);
}

// An error occurred.  This will be immediately followed by didFinish.
-(void) networkManager:(id<AbstractNetworkManager>)networkManager didFail:(id)context
                 error:(NetworkManagerError)errorType httpStatus:(int)httpStatus data:(NSData*)data {
    
}

// Called when a call is done, either by error or by success.  You'll always
// get this callback, preceded either by didSucceed or didFail.
-(void) networkManager:(id<AbstractNetworkManager>)networkManager didFinish:(id)context {
    
}



@end
