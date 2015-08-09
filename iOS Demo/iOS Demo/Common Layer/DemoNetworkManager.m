//
//  DemoNetworkManager.m
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

#import "DemoNetworkManager.h"
#import "NetworkCall.h"
#import "Logging.h"

NSString* const LOGTAG = @"network";

// Constants used in case nothing is specified:
double const kDefaultTimeoutSeconds = 8.0;
double const kMaintenanceTimerInterval = 0.25;
int const kDefaultNumRetries = 3;



@interface DemoNetworkManager ()

@property (nonatomic, retain) NSTimer* maintenanceTimer;
@property (nonatomic, retain) NSMutableSet* allNetworkCalls;

@property (nonatomic, retain) NetworkManagerStatistics* statistics;
@property (nonatomic) UInt64 totalSuccessfulCalls;
@property (nonatomic) double totalLatencySuccessfulCalls;

@end

@implementation DemoNetworkManager
@synthesize maintenanceTimer = _maintenanceTimer;
@synthesize allNetworkCalls = _allNetworkCalls;
@synthesize statistics = _statistics;
@synthesize totalSuccessfulCalls = _totalSuccessfulCalls;
@synthesize totalLatencySuccessfulCalls = _totalLatencySuccessfulCalls;

-(DemoNetworkManager*) init {
    if(self = [super init]) {
        self.allNetworkCalls = [[NSMutableSet alloc] init];
        self.maintenanceTimer = [NSTimer scheduledTimerWithTimeInterval:kMaintenanceTimerInterval target:self
                                                               selector:@selector(maintenanceTimerFired) userInfo:nil repeats:YES];
        self.statistics = [[NetworkManagerStatistics alloc] init];
    }
    return self;
}


// Returns the current statistics of this NetworkManager:
-(NetworkManagerStatistics*) currentStatistics {
    NetworkManagerStatistics* retval = nil;
    
    @synchronized (self) {
        retval = [self.statistics copy];
        retval.date = [NSDate date];
        
        retval.numRetriesInFlight = retval.numCallsInFlight = 0;
        retval.numCallsInFlight = self.allNetworkCalls.count;
        for(NetworkCall* call in self.allNetworkCalls) {
            if(call.numRetries > 0 && call.connection != nil) {
                retval.numRetriesInFlight++;
            }
        }
        
        retval.totalSuccessfulCalls = self.totalSuccessfulCalls;
        retval.meanAverageLatency = self.totalLatencySuccessfulCalls / ((double) self.totalSuccessfulCalls);
        retval.totalFailedCalls = retval.failuresNoConnection + retval.failuresTimedOut
                                + retval.failuresBadRequest   + retval.failuresBadServer
                                + retval.failuresInternalError;
    }
    
    return retval;
}

// These helpers are shortcuts to the methods below.  They build the URL
// request and start the call for you.  The downside is that you can't
// set the HTTP headers or do any other special changes.
-(void) get:(NSString*)urlString delegate:(id<NetworkManagerDelegate>)delegate context:(id)context {
    NSMutableURLRequest* request = [self buildURLRequest:urlString];
    [request setHTTPMethod:@"GET"];
    
    [self startNetworkCall:request withDelegate:delegate onMainThread:YES withTimeout:kDefaultTimeoutSeconds withNumRetries:kDefaultNumRetries withContext:context];
}
-(void) post:(NSString*)urlString delegate:(id<NetworkManagerDelegate>)delegate context:(id)context data:(NSData*)data {
    NSMutableURLRequest* request = [self buildURLRequest:urlString];
    [request setHTTPMethod:@"POST"];
    if(data != nil) [request setHTTPBody:data];
    
    [self startNetworkCall:request withDelegate:delegate onMainThread:YES withTimeout:kDefaultTimeoutSeconds withNumRetries:kDefaultNumRetries withContext:context];
}

// Call this to construct an NSMutableURLRequest object that you can
// modify as you choose.  Then pass it to the startNetworkCall method.
-(NSMutableURLRequest*) buildURLRequest:(NSString*)urlString {
    NSMutableURLRequest* request = nil;
    
    if([urlString length] != 0) {
        NSURL* url = [NSURL URLWithString:urlString];
        
        if(url != nil) {
            request = [[NSMutableURLRequest alloc] initWithURL:url];
            
            // We want to force a reload every time.
            request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
            
            // Some other params.  Connection=close increases reliability because the underlying NSURLConnection seems to never let go of calls sometimes.
            [request setValue:@"close" forHTTPHeaderField:@"Connection"];
            [request setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
        }
    }
    
    return request;
}

-(void) startNetworkCall:(NSMutableURLRequest*)request
            withDelegate:(id<NetworkManagerDelegate>)delegate
            onMainThread:(BOOL)onMainThread
             withTimeout:(double)timeout
          withNumRetries:(unsigned)numRetries
             withContext:(id)context {
    
    // The sending code sets this to a value other than NoError if we should call back "failure" immediately.
    NetworkManagerError earlyCallbackError = NetworkManagerErrorNoError;
    BOOL makeStartedCallCallback = FALSE;
    
    // Let's build a NetworkCall to track this connection:
    NetworkCall* call = [[NetworkCall alloc] initWithManager:self delegate:delegate delegateContext:context timeout:timeout maxRetries:numRetries];
    call.request = request;
    call.urlString = request.URL.absoluteString;
    call.runLoop = onMainThread ? [NSRunLoop mainRunLoop] : [NSRunLoop currentRunLoop];
    
    @synchronized (self) {
        // Set up the timeout on the NSURLRequest... this is different than the timeout on the NetworkCall
        // object and in fact will probably never get encountered.  There's some evidance that it's not
        // obeyed by NSURLConnection anyway.  This network manager handles its own timeouts for that reason.
        if(timeout <= 0.0) timeout = kDefaultTimeoutSeconds;
        request.timeoutInterval = timeout*2.0;
        
        // If there is no network connection or other issues, the below method will return NO and we'll fail early:
        if(![NSURLConnection canHandleRequest:request]) {
            LogD(LOGTAG, @"NSURLConnection cannot handle request %@ ... possibly no connection!", request);
            earlyCallbackError = NetworkManagerErrorNoConnection;
        } else {
            [self.allNetworkCalls addObject:call];
            [self startCallHelper:call];
            makeStartedCallCallback = TRUE;
            
            LogD(LOGTAG, @"Started call: %@ %@", request.HTTPMethod, [request.URL absoluteString]);
        }
    }
    
    // Outside the synchronized block, make callbacks as needed:
    if(earlyCallbackError != NetworkManagerErrorNoError) {
        [self makeFailureCallback:call httpCode:-1 networkManagerError:earlyCallbackError error:nil];
    } else if(makeStartedCallCallback) {
        if(delegate != nil) {
            if([delegate respondsToSelector:@selector(networkManager:didStartCall:)]) {
                [delegate networkManager:self didStartCall:context];
            }
        }
    }
}

-(void) cancelForDelegate:(id<NetworkManagerDelegate>)delegate withContext:(id)context {
    @synchronized (self) {
        // TASK: The right way to structure this is to have a map (i.e. NSMutableDictionary) of
        // delegates (weakly held!) to network calls.  This requires a little bit of finageling
        // because the delegates are held weakly... but it can be done.  I'm not going to do
        // that now, however, so we default to this O(n) search strategy.
        for(NetworkCall* call in self.allNetworkCalls) {
            if(call.delegate == delegate && call.delegateContext == context) {
                [self unTrackCall:call];
            }
        }
    }
}



// Methods called by NetworkCall:
-(void) networkCall:(NetworkCall*)call didRecieveResponse:(NSURLResponse*)response {
    BOOL connectionIsValid = FALSE;
    BOOL shouldCallBackFailure = FALSE;
    int httpCode = -100;
    int size = -1;
    NSDictionary* allHeaders = nil;
    
    @synchronized (self) {
        if([self networkCallIsValidHelper:call]) {
            BOOL errorOccured = FALSE;
            
            if([response isKindOfClass:[NSHTTPURLResponse class]]) {
                // Parse this as an HTTP response:
                NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                
                httpCode = (int)httpResponse.statusCode;
                allHeaders = httpResponse.allHeaderFields;
                
                if(httpCode >= 400) {
                    errorOccured = TRUE;
                } else {
                    // got a successful 200 response!
                    connectionIsValid = TRUE;
                    
                    // let's parse the content-length really quick while we're here:
                    NSString* contentLengthString = [allHeaders valueForKey:@"Content-Length"];
                    
                    if(contentLengthString == nil) {
                        LogI(@"DemoNetworkManager could not find Content-Length on call to URL %@", call.urlString);
                    } else {
                        int tmp = -1;
                        NSScanner* scanner = [[NSScanner alloc] initWithString:contentLengthString];
                        if([scanner scanInt:&tmp]) {
                            size = tmp;
                        }
                    }
                    
                    LogD(LOGTAG, @"Recieved %d response (Content-Length %d) from URL %@", httpCode, size, call.urlString);
                }
                
            } else {
                LogE(LOGTAG, @"Recieved response that was NOT an HTTP response: %@!  URL is %@", response, call.urlString);
                errorOccured = TRUE;
            }
            
            // If there was something wrong with what was returned, we'll use the retry-or-fail flow
            // that goes up to the max number of retries and then stops.  If the call is retried, all
            // callbacks will stop and start over again with a new connection, so we don't have to
            // worry about an errant didFinishLoading call from this network call.
            if(errorOccured) {
                shouldCallBackFailure = [self retryOrFail:call withError:[self decodeError:httpCode error:nil hint:0]];
            }
            
        } else {
            LogW(LOGTAG, @"Recieved response to unbound connection wrapper %@!  URL is %@", call, call.urlString);
        }
    }
    
    if(shouldCallBackFailure) {
        [self makeFailureCallback:call httpCode:httpCode networkManagerError:0 error:nil];
    } else if(connectionIsValid && call.delegate != nil) {
        // call back saying we recieved the header:
        if([call.delegate respondsToSelector:@selector(networkManager:didLoadHeader:size:headers:)]) {
            [call.delegate networkManager:self didLoadHeader:call.delegateContext size:size headers:allHeaders];
        }
    }
}

-(void) networkCallDidFinishLoading:(NetworkCall*)call {
    BOOL connectionIsValid = FALSE;
    
    @synchronized (self) {
        if([self networkCallIsValidHelper:call]) {
            // This call finished successfully, so we'll permanently wipe it from our records (we can prove
            // that we won't get here unless the call has successfully passed didRecieveResponse without
            // hitting a retry-or-fail case.
            connectionIsValid = TRUE;
            [self unTrackCall:call];
            
            // now we can update some stats:
            self.totalSuccessfulCalls ++;
            self.totalLatencySuccessfulCalls += [[NSDate date] timeIntervalSinceDate:call.dateCallStarted];
        } else {
            LogW(LOGTAG, @"Recieved response to unbound connection wrapper %@!  URL is %@", call, call.urlString);
        }
    }
    
    if(connectionIsValid) {
        // call back with success:
        if(call.delegate != nil) {
            // note that this method is "required" by the protocol, so we foregoe a guard:
            [call.delegate networkManager:self didSucceed:call.delegateContext data:call.data];
            
            // call connection finished, if supported:
            if([call.delegate respondsToSelector:@selector(networkManager:didFinish:)]) {
                [call.delegate networkManager:self didFinish:call.delegateContext];
            }
        }
    }
}

-(void) networkCall:(NetworkCall*)call didFailWithError:(NSError*)error {
    BOOL makeFailureCallback = FALSE;
    @synchronized (self) {
        makeFailureCallback = [self retryOrFail:call withError:[self decodeError:-1 error:error hint:0]];
    }
    
    if(makeFailureCallback) {
        [self makeFailureCallback:call httpCode:-1 networkManagerError:0 error:error];
    }
}

// CALL THIS FROM A SYNCHRONIZED BLOCK!!!
-(BOOL) networkCallIsValidHelper:(NetworkCall*)call {
    return (call != nil) && ([self.allNetworkCalls containsObject:call]);
}



// CALL THIS FROM A SYNCHRONIZED BLOCK!!!
// Returns TRUE if the call failed permanently, so that appropriate callbacks can be made.
-(BOOL) retryOrFail:(NetworkCall*)call withError:(NetworkManagerError)error {
    BOOL failedCall = TRUE;
    if(call != nil) {
        // For now, we only retry if there haven't been the max number of retries yet:
        // TASK: It's possible to do some other stuff here, too, like making decisions
        // about whether to retry based on the HTTP error code, etc.  But sometimes an
        // overloaded server will return 404's when the resource is actually retrievable.
        if(call.numRetries < call.maxRetries) {
            // We're going to retry this call.  Increment numRetries
            // by one and reset, then restart the call.
            LogD(LOGTAG, @"Retrying call to %@ (%p).  Retry %d of %d", call.urlString, call, call.numRetries, call.maxRetries);
            call.numRetries++;
            [self clearInternalConnectionForCall:call];
            [self startCallHelper:call];
            failedCall = FALSE;
            self.statistics.totalNumRetries++;
        } else {
            LogD(LOGTAG, @"Failing call to %@ (%p) after %d retries", call.urlString, call, call.numRetries);
            [self unTrackCall:call];
        }
        
        // Update some statistics:
        switch (error) {
            default: case NetworkManagerErrorNoError: break;
            case NetworkManagerErrorNoConnection:   self.statistics.failuresNoConnection++; break;
            case NetworkManagerErrorTimedOut:       self.statistics.failuresTimedOut++;     break;
            case NetworkManagerErrorBadRequest:     self.statistics.failuresBadRequest++;   break;
            case NetworkManagerErrorBadServer:      self.statistics.failuresBadServer++;    break;
            case NetworkManagerErrorInternal:       self.statistics.failuresInternalError++;break;
        }
    }
    return failedCall;
}


// CALL THIS FROM A SYNCHRONIZED BLOCK!!!
-(void) startCallHelper:(NetworkCall*)call {
    if(call.connection != nil) {
        [self clearInternalConnectionForCall:call];
    }
    
    NSURLConnection* newConnection = [[NSURLConnection alloc] initWithRequest:call.request delegate:call startImmediately:FALSE];
    [call setConnection:newConnection];
    NSRunLoop* runloop = call.runLoop;
    [newConnection scheduleInRunLoop:runloop forMode:NSRunLoopCommonModes];
    
    // Finally, we can start this connection:
    [newConnection start];
    call.dateCallStarted = [NSDate date];
}


// CALL THIS FROM A SYNCHRONIZED BLOCK!!!
-(void) clearInternalConnectionForCall:(NetworkCall*)call {
    [call.connection cancel];
    call.connection = nil;
    call.data = [[NSMutableData alloc] init];
    call.dateCallStarted = nil;
}


// CALL THIS FROM A SYNCHRONIZED BLOCK!!!
-(void) unTrackCall:(NetworkCall*)call {
    [call.connection cancel];
    [self.allNetworkCalls removeObject:call];
}


// Pass a NetworkManagerError if you can determine what it is,
// otherwise just pass what you can (http code, NSError) and
// this method will try to figure it out.  Passing an HTTP code
// of -100 indicates an internal error, so pass HTTP code of -1
// to indicate no specific error.
-(NetworkManagerError) decodeError:(int)httpCode error:(NSError*)error hint:(NetworkManagerError)hintErrorType {
    if(hintErrorType == NetworkManagerErrorNoError) {
        hintErrorType = NetworkManagerErrorTimedOut;
        if(httpCode >= 400 && httpCode < 500) {
            hintErrorType = NetworkManagerErrorBadRequest;
        } else if (httpCode > 500) {
            hintErrorType = NetworkManagerErrorBadServer;
        }
        // TASK: Parse other error types here.  It's be possible to pull apart the
        // NSError to discover more about which NetworkManagerError to pass back.
        // As an example, we'll check for one connection-offline error (CFNetwork
        // code -1009).  Ideally we'd parse based on error codes instead of strings.
        else if([error.domain isEqualToString:@"NSURLErrorDomain"]
                && [[error.userInfo objectForKey:@"NSLocalizedDescription"] isEqualToString:@"The Internet connection appears to be offline."]) {
            hintErrorType = NetworkManagerErrorNoConnection;
        }
    }
    
    return hintErrorType;
}



// This helper should be called OUTSIDE the synchronized block, after you've
// cleaned up and untracked the network call.
-(void) makeFailureCallback:(NetworkCall*)call httpCode:(int)httpCode networkManagerError:(NetworkManagerError)errorType error:(NSError*)error {
    
    if(errorType == NetworkManagerErrorNoError) {
        errorType = [self decodeError:httpCode error:error hint:NetworkManagerErrorNoError];
    }
    
    // call back with failure:
    if(call.delegate != nil) {
        // note that this method is "required" by the protocol, so we foregoe a guard:
        [call.delegate networkManager:self didFail:call.delegateContext error:errorType httpStatus:httpCode data:call.data];
        
        // call connection finished (if supported):
        if([call.delegate respondsToSelector:@selector(networkManager:didFinish:)]) {
            [call.delegate networkManager:self didFinish:call.delegateContext];
        }
    }
}



// This method is called cyclically by the maintenance timer.  Whenever the timer fires,
// we'll check all the network connections to see if any have timed out and we'll either
// restart or fail them appropriately.  When the app gets backgrounded, all timers that
// would have fired during the interim time will fire immediately.  Therefore it's much
// better to have only one timer than a separate timer inside each NetworkCall object.
// In a robust system with a lot of timers it is useful to delay the firing of various
// timers once the app returns to life so that a thousand parts of the app don't start
// trying to do work all at the same time (the system has been known to terminate apps
// for taking too much CPU time right after resuming from the background).
-(void) maintenanceTimerFired {
    NSMutableArray* callsToFail = [[NSMutableArray alloc] init];
    
    @synchronized (self) {
        NSDate* now = [NSDate date];
        double delta = 0.0;
        
        // Determine if any calls need to be retried (or failed) by looping
        // through and checking the timeout interval.
        for(NetworkCall* call in self.allNetworkCalls) {
            delta = [now timeIntervalSinceDate:call.dateCallStarted];
            if(call.dateCallStarted != nil && delta > call.timeout) {
                LogD(LOGTAG, @"Call to %@ (%p) has timed out after %lf seconds.", call.urlString, call, delta);
                if([self retryOrFail:call withError:NetworkManagerErrorTimedOut]) {
                    [callsToFail addObject:call];
                }
            }
        }
    }
    
    // If any calls were failed in the block above, call back to their delegates:
    for(NetworkCall* call in callsToFail) {
        [self makeFailureCallback:call httpCode:-1 networkManagerError:NetworkManagerErrorTimedOut error:nil];
    }
}





@end
