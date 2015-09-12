//
//  NKNetworkManager.h
//  iOS Demo
//
//  Created by Christopher Cornelius on 9/3/15.
//
//

/** A full-fledged network manager conforming to the AbstractNetworkManager protocol.
    Has a multi-level priority system and a simple but effective method for setting
    behaviors around retries, timeouts, redirects, and other fine-tuning of the way
    network calls are handled.  This is achieved through the NKCallBehaviorURLRequest
    which replaces standard NSMutableURLRequests as used in AbstractNetworkManager. */

#import <Foundation/Foundation.h>
#import "AbstractNetworkManager.h"
#import "NKCallBehaviorURLRequest.h"
#import "NKURLConnectionBridge.h"

@interface NKNetworkManager : NSObject <AbstractNetworkManager>

// Build an NKNetworkManager with a given NKURLConnectionBridge.  In production, use an
// instance of NKDefaultURLConnectionBridge.  For testing, you can supply something else
// that can be a factory for dummy connection objects.
-(NKNetworkManager*) initWithConnectionBridge:(id<NKURLConnectionBridge>)bridge;

// This property holds the default NKCallBehaviorURLRequest for this network manager.
// You can modify it to change the ways the network manager will handle calls by default.
// The buildURLRequest: method returns a copy of this, modified with requestType and urlString.
@property (nonatomic, retain) NKCallBehaviorURLRequest* defaultCallBehavior;


// This method is from AbstractNetworkManager but is modified to
// use NKCallBehaviorURLRequest instead of just NSMutableURLRequest.
// Call it to get a NKCallBehaviorURLRequest object to configure for
// the network call you want to send.
-(NKCallBehaviorURLRequest*) buildURLRequest:(NSString*)urlString forRequestType:(NSString*)requestType;


// These methods are directly from AbstractNetworkManager and are nice helpers
// if you just want to use the default behavior:
-(void) get:(NSString*)urlString  delegate:(id<NetworkManagerDelegate>)delegate context:(id)context;
-(void) post:(NSString*)urlString delegate:(id<NetworkManagerDelegate>)delegate context:(id)context data:(NSData*)data;
-(void) cancelForDelegate:(id<NetworkManagerDelegate>)delegate withContext:(id)context;


// Call this method to start a network call if you are going to set all the options
// on the NKCallBehaviorURLRequest object instead of using the older startNetworkCall method below.
-(void) startNetworkCall:(NKCallBehaviorURLRequest*)request
            withDelegate:(id<NetworkManagerDelegate>)delegate
             withContext:(id)context;


// It's recommended that you don't actually use this method!  It's better to use the other
// startNetworkCall method above because you can specify all these options and more on the
// NKCallBehaviorURLRequest object you use to start the call.
-(void) startNetworkCall:(NSMutableURLRequest*)request
            withDelegate:(id<NetworkManagerDelegate>)delegate
            onMainThread:(BOOL)onMainThread
             withTimeout:(double)timeout
          withNumRetries:(unsigned)numRetries
             withContext:(id)context;


// This is wired to return FALSE because NKNetworkManager does not support this kind of
// testing.  Instead see the other test cases for NKNetworkManager.
-(BOOL) overrideTestingURLConnectionClass:(Class)testingURLConnectionClass;


@end
