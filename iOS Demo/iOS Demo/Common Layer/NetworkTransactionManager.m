//
//  NetworkTransactionManager.m
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

#import "NetworkTransactionManager.h"
#import "Logging.h"
#import "JSONHelpers.h"

NSString* const LOGTAG_NTM = @"networktransaction";

/** This class is used to wrap a callback so things don't get out of hand.  I'm
    starting it with an underscore because of some of the flat-namespace issues
    that Objective-C has ( see: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/LoadingCode/Tasks/NameConflicts.html ).*/

@interface _InternalCallbackWrapper : NSObject

// This is set during the call:
@property (nonatomic) int httpStatus;

// These are set at the beginning:
@property (nonatomic, retain) NSString* urlString;
@property (nonatomic, weak)   id<NetworkTransactionManagerDelegate> delegate;
@property (nonatomic, retain) id delegateContext;
@property (nonatomic, copy) NetworkTransactionManagerSuccessHandler successHandler;
@property (nonatomic, copy) NetworkTransactionManagerFailureHandler failureHandler;

@end

@implementation _InternalCallbackWrapper
@synthesize httpStatus = _httpStatus, urlString = _urlString, delegate = _delegate, delegateContext = _delegateContext, successHandler = _successHandler, failureHandler = _failureHandler;
@end


/** The internal/private properties of NetworkTransactionManager*/
@interface NetworkTransactionManager () <NetworkManagerDelegate>

@property (nonatomic, weak) id<AbstractNetworkManager> networkManager;

@property (nonatomic, retain) NSMutableSet* allCallbackWrappers;

@end

@implementation NetworkTransactionManager
@synthesize networkManager = _networkManager;
@synthesize allCallbackWrappers = _allCallbackWrappers;

-(NetworkTransactionManager*) initWithNetworkManager:(id<AbstractNetworkManager>)networkManager {
    if(self = [super init]) {
        self.networkManager = networkManager;
        self.allCallbackWrappers = [[NSMutableSet alloc] init];
    }
    return self;
}


/** These four methods are just helpers and therefore all look identical. */
// For delegation:
-(void) get:(NSString*)url withData:(NSDictionary*)jsonData
   delegate:(id<NetworkTransactionManagerDelegate>)delegate context:(id)context {
    
    _InternalCallbackWrapper* wrapper = [[_InternalCallbackWrapper alloc] init];
    wrapper.delegate = delegate;
    wrapper.delegateContext = context;
    wrapper.successHandler = NULL;
    wrapper.failureHandler = NULL;
    wrapper.urlString = url;

    [self sendRequestForWrapper:wrapper withData:jsonData isGetRequest:TRUE];
}
-(void) post:(NSString*)url withData:(NSDictionary*)jsonData
    delegate:(id<NetworkTransactionManagerDelegate>)delegate context:(id)context {
    
    _InternalCallbackWrapper* wrapper = [[_InternalCallbackWrapper alloc] init];
    wrapper.delegate = delegate;
    wrapper.delegateContext = context;
    wrapper.successHandler = NULL;
    wrapper.failureHandler = NULL;
    wrapper.urlString = url;
    
    [self sendRequestForWrapper:wrapper withData:jsonData isGetRequest:FALSE];
}
// For block callbacks:
-(void) get:(NSString*)url withData:(NSDictionary*)jsonData
    success:(NetworkTransactionManagerSuccessHandler)successHandler
    failure:(NetworkTransactionManagerFailureHandler)failureHandler {

    _InternalCallbackWrapper* wrapper = [[_InternalCallbackWrapper alloc] init];
    wrapper.delegate = nil;
    wrapper.delegateContext = nil;
    wrapper.successHandler = successHandler;
    wrapper.failureHandler = failureHandler;
    wrapper.urlString = url;
    
    [self sendRequestForWrapper:wrapper withData:jsonData isGetRequest:TRUE];
}
-(void) post:(NSString*)url withData:(NSDictionary*)jsonData
     success:(NetworkTransactionManagerSuccessHandler)successHandler
     failure:(NetworkTransactionManagerFailureHandler)failureHandler {
    
    _InternalCallbackWrapper* wrapper = [[_InternalCallbackWrapper alloc] init];
    wrapper.delegate = nil;
    wrapper.delegateContext = nil;
    wrapper.successHandler = successHandler;
    wrapper.failureHandler = failureHandler;
    wrapper.urlString = url;
    
    [self sendRequestForWrapper:wrapper withData:jsonData isGetRequest:FALSE];
}


-(void) cancelFromDelegate:(id<NetworkTransactionManagerDelegate>)delegate withContext:(id)context {
    @synchronized (self) {
        // Like in the DemoNetworkManager, this search should really use a map of some sort
        // for efficiency.  But I'll do it this way for now so I can get on to other stuff.
        _InternalCallbackWrapper* wrapper = nil;
        for(_InternalCallbackWrapper* w in self.allCallbackWrappers) {
            if(w.delegate == delegate && w.delegateContext == context) {
                wrapper = w;
                break;
            }
        }
        
        // Now cancel that wrapper's call and clean up:
        if(wrapper != nil) {
            if([self.networkManager respondsToSelector:@selector(cancelForDelegate:withContext:)]) {
                [self.networkManager cancelForDelegate:self withContext:wrapper];
            }
            [self cleanUpAfterCall:wrapper];
        }
    }
}


// Internal method for sending a request:
-(void) sendRequestForWrapper:(_InternalCallbackWrapper*)wrapper withData:(NSDictionary*)jsonData isGetRequest:(BOOL)isGetRequest {
    if(wrapper != nil) {
        @synchronized (self) {
            if([self.allCallbackWrappers containsObject:wrapper]) {
                LogW(@"LOGTAG", @"Got already-bound callback wrapper %@!  Not starting another call.");
            } else {
                // Add the wrapper to our callback list:
                [self.allCallbackWrappers addObject:wrapper];
                wrapper.httpStatus = -1;
                
                // Make a URLRequest and start the call:
                NSMutableURLRequest* request = [self.networkManager buildURLRequest:wrapper.urlString forRequestType:(isGetRequest ? @"GET" : @"POST")];
                request.HTTPBody = [JSONHelpers toData:jsonData];
                
                
                [self.networkManager startNetworkCall:request withDelegate:self onMainThread:TRUE withTimeout:8.0 withNumRetries:3 withContext:wrapper];
            }
        }
    }
}


// Callbacks from the network kit:
// Called when a call is started.  This will happen immediately when you call
// a method on NetworkManager that falls down to the startNetworkCall method.
// It will happen in the same flow (synchronously) with your call into
// startNetworkCall, and it will happen only if there are no errors starting
// the call.  If there is an error preflighting the call, you'll get the onError
// callback instead.
-(void) networkManager:(id<AbstractNetworkManager>)networkManager didStartCall:(id)context {
    // nothing to do here
}

// Called when the network manager loads the header for the remote resource.
// This allows the delegate to choose to cancel the call if one of the the
// HTTP headers is not as expected, and it gives the Content-Length, too.
-(void) networkManager:(id<AbstractNetworkManager>)networkManager didLoadHeader:(id)context
                  size:(int)size headers:(NSDictionary*)allHeaderFields {
    // Nothing to do with the headers for now.
}

// Success!  This will be followed by didFinish.
-(void) networkManager:(id<AbstractNetworkManager>)networkManager didSucceed:(id)context data:(NSData*)data {
    _InternalCallbackWrapper* wrapper = nil;
    NSDictionary* json = nil;
    BOOL hadJSONError = FALSE;
    NetworkManagerError verificationError = NetworkManagerErrorNoError;
    
    @synchronized (self) {
        if([self.allCallbackWrappers containsObject:context]) {
            wrapper = (_InternalCallbackWrapper*)context;
            if(data != nil) {
                json = [self decodeJSON:data];
                
                // this will tell us if there was a verification error:
                verificationError = [self verifyJSON:json];
                
                // if we had data but couldn't decode JSON, it's an error:
                if(json == nil) {
                    hadJSONError = TRUE;
                }
                
            }
            
            // Note, we don't need to do any cleanup because we'll do that in didFinish, below.
        } else {
            // TODO: Silent failure isn't good!
        }
    }
    
    if(wrapper != nil) {
        if(hadJSONError || verificationError != NetworkManagerErrorNoError) {
            // We had a JSON deserialization error!  Call back:
            if(wrapper.delegate != nil) {
                [wrapper.delegate networkTransactionManager:self didFail:wrapper.delegateContext
                                               networkError:verificationError
                                                 httpStatus:200
                                        jsonDecodingFailure:TRUE
                                                   jsonData:json
                                                    rawData:(NSData*)data];
            }
            
            if(wrapper.failureHandler != NULL) {
                wrapper.failureHandler(verificationError, 200, YES, json);
            }
        } else {
            // Successfully recieved JSON!  We'll call back to the delegate and the success block
            if(wrapper.delegate != nil) {
                [wrapper.delegate networkTransactionManager:self didSucceed:wrapper.delegateContext jsonData:json];
            }
            
            if(wrapper.successHandler != NULL) {
                wrapper.successHandler(json);
            }
        }
    }
}

// An error occurred.  This will be immediately followed by didFinish.
-(void) networkManager:(id<AbstractNetworkManager>)networkManager didFail:(id)context
                 error:(NetworkManagerError)errorType httpStatus:(int)httpStatus data:(NSData*)data {
    _InternalCallbackWrapper* wrapper = nil;
    NSDictionary* json = nil;
    
    @synchronized (self) {
        if([self.allCallbackWrappers containsObject:context]) {
            wrapper = (_InternalCallbackWrapper*)context;
            if(json != nil) json = [self decodeJSON:data];
            
            // Note, we don't need to do any cleanup because we'll do that in didFinish, below.
        } else {
            // TODO: Silent failure isn't good!
        }
    }
    
    if(wrapper != nil) {
        // We had an error!  Even if we couldn't decode JSON, we'll pass NO for jsonDecodingFailure
        if(wrapper.delegate != nil) {
            [wrapper.delegate networkTransactionManager:self didFail:wrapper.delegateContext
                                           networkError:errorType
                                             httpStatus:httpStatus
                                    jsonDecodingFailure:NO
                                               jsonData:json
                                                rawData:data];
        }
        
        if(wrapper.failureHandler != NULL) {
            wrapper.failureHandler(errorType, httpStatus, NO, json);
        }
    }
}

// Called when a call is done, either by error or by success.  You'll always
// get this callback, preceded either by didSucceed or didFail, UNLESS you
// cancel the call using the cancelForDelegate method.  If a call is canceled,
// the manager is not obligated to do any more callbacks.
-(void) networkManager:(id<AbstractNetworkManager>)networkManager didFinish:(id)context {
    @synchronized (self) {
        if([self.allCallbackWrappers containsObject:context]) {
            // We'll take this as the time to clean up, since we're guaranteed to get it:
            [self cleanUpAfterCall:(_InternalCallbackWrapper*)context];
        }
    }
}



// Helper which decodes JSON from an NSData if possible.  Returns nil if there's a parse error.
-(NSDictionary*) decodeJSON:(NSData*)data {
    NSDictionary* json = nil;
    
    if(data != nil) {
        json = [JSONHelpers toJSON:data];
    }
    
    return json;
}


// Helper for subclassers to override if they want JSON content validation to determine success or failure:
-(NetworkManagerError) verifyJSON:(NSDictionary*)json {
    return NetworkManagerErrorNoError;
}


// CALL THIS FROM A SYNCHRONIZED BLOCK!!
-(void) cleanUpAfterCall:(_InternalCallbackWrapper*)wrapper {
    [self.allCallbackWrappers removeObject:wrapper];
}




@end
