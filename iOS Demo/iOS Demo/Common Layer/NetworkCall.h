//
//  NetworkCall.h
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

#import <Foundation/Foundation.h>
#import "DemoNetworkManager.h"

/** This class is a wrapper for NSURLConnection.  It serves as the
 delegate for a NSURLConnection and it passes the callbacks
 straight through to the network manager.  In Java, this would
 be even slicker because it would be a nested class but we'll
 have to make do with the language we have here.  So this class
 is mostly a dumb struct that keeps properties available and passes
 delegate callbacks through to DemoNetworkManager.
 
 Keep in mind that this class and DemoNetworkManager are interdependant.
 I was going to put them in the same file but it got too long. */

@interface NetworkCall : NSObject

// Remember to hold the manager as a weak reference!
@property (nonatomic, weak) DemoNetworkManager* manager;

// The delegate for this call:
@property (nonatomic, weak)   id<NetworkManagerDelegate> delegate;
@property (nonatomic, retain) id delegateContext;

// Basic information used to build the NSURLConnection.
@property (nonatomic, retain) NSString* urlString;
@property (nonatomic, retain) NSURLRequest* request;
@property (nonatomic, retain) NSRunLoop* runLoop;

// Properties of this call.  We track these ourselves because we can't seem to trust
// NSURLConnection in areas where service is spotty.  So timeouts and retries are
// enforced in the DemoNetworkManager layer instead of letting the lower (Apple)
// layers take care of it instead of leaving calls hanging indefinately.
@property (nonatomic) unsigned numRetries;
@property (nonatomic) unsigned maxRetries;
@property (nonatomic) double timeout;
@property (nonatomic, retain) NSDate* dateCallStarted;

// Store the connection object:
@property (nonatomic, retain) NSURLConnection* connection;

// Incrementally append the returned data:
@property (nonatomic, retain) NSMutableData* data;

-(NetworkCall*) initWithManager:(DemoNetworkManager*)manager
                       delegate:(id<NetworkManagerDelegate>)delegate
                delegateContext:(id)delegateContext
                        timeout:(double)timeout
                     maxRetries:(int)maxRetries;


@end