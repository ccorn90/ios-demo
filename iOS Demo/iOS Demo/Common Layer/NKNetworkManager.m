//
//  NKNetworkManager.m
//  iOS Demo
//
//  Created by Christopher Cornelius on 9/3/15.
//
//

#import "NKNetworkManager.h"
#import "NKCallBehaviorURLRequest.h"
#import "WeakTargetTimer.h"
#import "Logging.h"
#import "SharedThreadPool.h"
#import <pthread.h>

// The following ae #defines instead of consts because
// symbols are treated uniquely in the system.  Oh, C.
#define kMaintenanceTimerInterval 0.25


@interface NKNetworkManager () {
    NSString* LOGTAG;
    
    // This set holds an NSMutableSet for each level of call priority.
    NSMutableSet* _callsInFlight[NK_NUM_CALL_PRIORITIES];

    // This array holds an NSMutableArray for each level of call priority.
    NSMutableSet* _callsWaiting[NK_NUM_CALL_PRIORITIES];
    
    // This NSMapTable is the master endpoint for all delegation checks.
    // It's easy to look up by delegate (and the delegates are held weakly!)
    NSMapTable*   _callsByDelegate;
}

// Properties that are basic to the operation of this object:
@property (nonatomic, retain) NSObject* lock;
@property (nonatomic, retain) id<NKURLConnectionBridge> bridge;


// The maintenance timer runs on the global NKNetworkManager thread.
@property (nonatomic, retain) WeakTargetTimer*  maintenanceTimer;

@end


@implementation NKNetworkManager

#pragma mark - Lifecycle methods

// This is wired to return FALSE since NKNetworkManager has its own set of tests.
-(BOOL) overrideTestingURLConnectionClass:(Class)testingURLConnectionClass {
    return FALSE;
}

-(NKNetworkManager*) initWithConnectionBridge:(id<NKURLConnectionBridge>)bridge {
    if(self = [super init]) {
        // Set up the basics for the network manager:
        LOGTAG = @"NKNetworkManager";
        self.lock = [[NSObject alloc] init];
        self.bridge = bridge;
        
        // Set up the three internal private vars: _callsInFlight, _callsWaiting, and _callsByDelegate:
        _callsByDelegate = [[NSMapTable alloc] initWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableWeakMemory capacity:20];
        for(NSUInteger i = 0; i < NK_NUM_CALL_PRIORITIES; i++) {
            _callsInFlight[i] = [[NSMutableSet alloc] initWithCapacity:NKCallQuotasByPriority[i]];
            _callsWaiting [i] = [[NSMutableSet alloc] initWithCapacity:10];
        }
        
        // Start the maintenance timer - we do this by performing the selector to schedule the timer on the common thread:
        [self performSelector:@selector(scheduleMaintenanceTimer) onThread:[[SharedThreadPool singleton] subscribeToThreadWithIdentifer:nil]
                   withObject:nil waitUntilDone:FALSE modes:@[NSRunLoopCommonModes]];
        
        [[SharedThreadPool singleton] pinThread:YES withIdentifier:nil];

        
    }
    return self;
}

// This should only be called ONCE, in the initializer:
-(void) scheduleMaintenanceTimer {
    self.maintenanceTimer = [WeakTargetTimer timerWithTimerInterval:kMaintenanceTimerInterval target:self selector:@selector(maintenanceTimerFired) repeats:YES];
    [self.maintenanceTimer scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    LogD(LOGTAG, @"NKNetworkManager started timer on thread %@", [NSThread currentThread].name);
}

// This is fired every kMaintenanceTimerInterval seconds.
-(void) maintenanceTimerFired {

}

// In dealloc, make sure to invalidate the timer.
-(void) dealloc {
    [self.maintenanceTimer invalidate];
    [[SharedThreadPool singleton] unsubscribeThreadWithIdentifier:nil];
}


// This method is from AbstractNetworkManager but is modified to
// use NKCallBehaviorURLRequest instead of just NSMutableURLRequest.
// Call it to get a NKCallBehaviorURLRequest object to configure for
// the network call you want to send.
-(NKCallBehaviorURLRequest*) buildURLRequest:(NSString*)urlString forRequestType:(NSString*)requestType {
    NKCallBehaviorURLRequest* r = nil;
    
    if([urlString length] != 0) {
        NSURL* url = [NSURL URLWithString:urlString];
        
        if(url != nil) {
            // This will copy all the behaviors that happen by default.  The user can
            // modify them before calling startNetworkCall with this NKCallBehaviorURLRequest.
            @synchronized (self.lock) {
                r = [[NKCallBehaviorURLRequest alloc] init:self.defaultCallBehavior];
            }
            r.URL = url;
            
            // Set the request type.  Valid options are "GET" "HEAD" "POST" "PUT" "DELETE"
            [r setHTTPMethod:@"GET"];
            if([requestType isEqualToString:@"HEAD"] || [requestType isEqualToString:@"POST"] || [requestType isEqualToString:@"PUT"] || [requestType isEqualToString:@"DELETE"]) {
                [r setHTTPMethod:requestType];
            } else {
                LogW(LOGTAG, @"Request made with unsupported method %@!  Defaulting to GET request.  URL is %@", requestType, urlString);
            }
        }
    }
    
    return r;
}


// I'm overriding the accessors for defaultCallBehavior instead of just making
// them "atomic" properties because I want to guarantee that this will lock on
// self.lock when you try to set it.  Atomic just makes the accesses atomic to
// the variable, not to the whole process, which is what I want.
@synthesize defaultCallBehavior = _defaultCallBehavior;

-(void) setDefaultCallBehavior:(NKCallBehaviorURLRequest*)defaultCallBehavior {
    @synchronized (self.lock) {
        _defaultCallBehavior = defaultCallBehavior;
    }
}

-(NKCallBehaviorURLRequest*) defaultCallBehavior {
    NKCallBehaviorURLRequest* r = nil;
    @synchronized (self.lock) {
        r = _defaultCallBehavior;
    }
    return r;
}


// These methods are directly from AbstractNetworkManager and are nice helpers
// if you just want to use the default behavior:
-(void) get:(NSString*)urlString  delegate:(id<NetworkManagerDelegate>)delegate context:(id)context {
    NKCallBehaviorURLRequest* request = [self buildURLRequest:urlString forRequestType:@"GET"];
    [self startNetworkCall:request withDelegate:delegate withContext:context];
}

-(void) post:(NSString*)urlString delegate:(id<NetworkManagerDelegate>)delegate context:(id)context data:(NSData*)data {
    NKCallBehaviorURLRequest* request = [self buildURLRequest:urlString forRequestType:@"POST"];
    [self startNetworkCall:request withDelegate:delegate withContext:context];
}

-(void) cancelForDelegate:(id<NetworkManagerDelegate>)delegate withContext:(id)context {
    
}



// Call this method to start a network call if you are going to set all the options
// on the NKCallBehaviorURLRequest object instead of using the older startNetworkCall method below.
-(void) startNetworkCall:(NKCallBehaviorURLRequest*)request
            withDelegate:(id<NetworkManagerDelegate>)delegate
             withContext:(id)context {
    @synchronized (self.lock) {
        
        
    }
}


// It's recommended that you don't actually use this method!  It's better to use the other
// startNetworkCall method above because you can specify all these options and more on the
// NKCallBehaviorURLRequest object you use to start the call.
-(void) startNetworkCall:(NSMutableURLRequest*)a_request
            withDelegate:(id<NetworkManagerDelegate>)delegate
            onMainThread:(BOOL)onMainThread
             withTimeout:(double)timeout
          withNumRetries:(unsigned)numRetries
             withContext:(id)context {
    // We're supporting this method just to fulfill the protocol.  It's preferred to pass
    // in an NKCallBehaviorURLRequest instead.  Unless we somehow already haveo ne, we'll
    // need to build an NKCallBehaviorURLRequest to hold all the metadata information.
    NKCallBehaviorURLRequest* request = nil;
    if([a_request isKindOfClass:[NKCallBehaviorURLRequest class]]) {
        request = (NKCallBehaviorURLRequest*)a_request;
    } else {
        request = [self buildURLRequest:a_request.URL.absoluteString forRequestType:a_request.HTTPMethod];
    }
    
    // assert: we've made an NKCallBehaviorURLRequest.
    // Now populate the configuration options:
    request.callbackThread = onMainThread ? [NSThread mainThread] : [NSThread currentThread];
    request.timeoutSeconds = timeout;
    request.numRetries = numRetries;
    
    // Now we call the base method to send the call:
    [self startNetworkCall:request withDelegate:delegate withContext:context];
}


@end
