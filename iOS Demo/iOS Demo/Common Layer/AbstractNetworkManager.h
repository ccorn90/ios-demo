//
//  NetworkManagerInterface.h
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

/** The abstract interface for a Network Manager, and the protocol for
    NetworkManagerDelegate which is used for the callbacks. */

#import "NetworkManagerEnums.h"

@protocol NetworkManagerDelegate;

@protocol AbstractNetworkManager <NSObject>

// These helpers are shortcuts to the methods below.  They build the URL
// request and start the call for you.  The downside is that you can't
// set the HTTP headers or do any other special changes.
@optional
-(void) get:(NSString*)urlString  delegate:(id<NetworkManagerDelegate>)delegate context:(id)context;
-(void) post:(NSString*)urlString delegate:(id<NetworkManagerDelegate>)delegate context:(id)context data:(NSData*)data;


// Call this to construct an NSMutableURLRequest object that you can
// modify as you choose.  Then pass it to the startNetworkCall method.
@required
-(NSMutableURLRequest*) buildURLRequest:(NSString*)urlString forRequestType:(NSString*)requestType;

// Starts a network call for the given URL request.  Specify a delegate
// and a context if you want to have a specific bit of metadata returned
// with each callback to help you out.  If you pass FALSE for onMainThread,
// the callbacks will come on the thread from which you call startNetworkCall.
@required
-(void) startNetworkCall:(NSMutableURLRequest*)request
            withDelegate:(id<NetworkManagerDelegate>)delegate
            onMainThread:(BOOL)onMainThread
             withTimeout:(double)timeout
          withNumRetries:(unsigned)numRetries
             withContext:(id)context;


// Cancel a call.  Note that not all managers will implement this!  The manager
// is also not required to call any more delegate methods once cancelForDelegate
// is called, so make sure to do your own cleanup!
@optional
-(void) cancelForDelegate:(id<NetworkManagerDelegate>)delegate withContext:(id)context;



// This is a hook for testing.  It allows the test framework to specify a class for the
// networkManager to use instead of NSURLConnection for its insides.  Returns FALSE if
// the input was ignored.
@required
-(BOOL) overrideTestingURLConnectionClass:(Class)testingURLConnectionClass;

@end



// This protocol defines a delegate for all NetworkManager implementations.
@protocol NetworkManagerDelegate <NSObject>

// Called when a call is started.  This will happen immediately when you call
// a method on NetworkManager that falls down to the startNetworkCall method.
// It will happen in the same flow (synchronously) with your call into
// startNetworkCall, and it will happen only if there are no errors starting
// the call.  If there is an error preflighting the call, you'll get the onError
// callback instead.
@optional
-(void) networkManager:(id<AbstractNetworkManager>)networkManager didStartCall:(id)context;


// Called when the network manager redirects a call.  You can cache the returned
// URL if you want to make subsequent hits at the deep level as opposed to the top level.
@optional
-(void) networkManager:(id<AbstractNetworkManager>)networkManager didRedirectForContext:(id)context
                newURL:(NSString*)newURL httpStatus:(int)httpStatus;


// Called when the network manager loads the header for the remote resource.
// This allows the delegate to choose to cancel the call if one of the the
// HTTP headers is not as expected, and it gives the Content-Length, too.
@optional
-(void) networkManager:(id<AbstractNetworkManager>)networkManager didLoadHeader:(id)context
                  size:(int)size headers:(NSDictionary*)allHeaderFields;

// Success!  This will be followed by didFinish.
@required
-(void) networkManager:(id<AbstractNetworkManager>)networkManager didSucceed:(id)context data:(NSData*)data;

// An error occurred.  This will be immediately followed by didFinish.
@required
-(void) networkManager:(id<AbstractNetworkManager>)networkManager didFail:(id)context
                 error:(NetworkManagerError)errorType httpStatus:(int)httpStatus data:(NSData*)data;

// Called when a call is done, either by error or by success.  You'll always
// get this callback, preceded either by didSucceed or didFail, UNLESS you
// cancel the call using the cancelForDelegate method.  If a call is canceled,
// the manager is not obligated to do any more callbacks.
@optional
-(void) networkManager:(id<AbstractNetworkManager>)networkManager didFinish:(id)context;

@end