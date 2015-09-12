//
//  NKCallBehaviors.h
//  iOS Demo
//
//  Created by Christopher Cornelius on 9/3/15.
//
//

/** An extension of NSMutableURLRequest which has extra variables to configure the way
    NKNetworkManager will handle the call.  Note that the properties here don't actually
    change anything about the call... NKNetworkManager uses them to guide how it handles
    the call AFTER startNetworkCall: is called.
 
    You can modify any of the given variables and also do any of the things you'd normally
    do with an NSMutableURLRequest, like adding HTTP headers, changing the http method, etc.
 
    DO NOT try to change these values on a call in flight.
 
 **/


#import <Foundation/Foundation.h>


// Options for the priority of the call in the system.  Please read these notes about priorities!
//    - HIGH priority calls have no quota ( and as many HIGH priority calls as you
//          want can be active at a given time.  Be careful... too many active
//          calls at one time can cause the system to jam.  Try to only use HIGH
//          for UX-critical data loads, like streaming audio.
//    - MEDIUM allows 4 calls in flight simultaneously and is a good balance of
//          performance and gating.  Use this for most API calls that return data
//          to the user.
//    - LOW priority only has 2 calls in flight.  This is good for sending metrics
//          and other calls that need to get out eventually but aren't time-critical.
//    - BKG priority calls execute one at a time.  This would be the priority to
//          use for loading thumbnail images, posting big chunks of non-critical
//          data, updating large libraries of internal data, etc.

typedef enum {
    NKCallPriorityHigh   = 0,
    NKCallPriorityMedium = 1,
    NKCallPriorityLow    = 2,
    NKCallPriorityBkg    = 3,
    NK_NUM_CALL_PRIORITIES
} NKCallPriority;

// This array sets the number of possible active calls for each priority level
// (index from the enum above).  Zero is taken to mean "unlimited calls allowed
// simultaneously."  Don't modify this unless you REALLY know what you're doing!
static int const NKCallQuotasByPriority[NK_NUM_CALL_PRIORITIES] = {0, 4, 2, 1};

// Options for how delay is handled:
typedef enum {
    NKRetryDelayPolicyFixedInterval = 0,
    NKRetryDelayPolicyLogarithmicDelay,
} NKRetryDelayPolicy;

// Options for how retries are handled if there's been a redirect:
typedef enum {
    NKRedirectRetryPolicyRetryFromTopURL,
    NKRedirectRetryPolicyStoreRedirectStack,
} NKRedirectRetryPolicy;

@interface NKCallBehaviorURLRequest : NSMutableURLRequest


// This is a key variable to set - what priority is
// this call?  Defaults to NKCallPriorityMedium.
@property (nonatomic) NKCallPriority priority;

// On which thread is the call run within the system?
// Defaults to [NSThread mainThread] if nil.
@property (nonatomic, retain) NSThread* callbackThread;

// Compression, protocols allowed, etc
@property (nonatomic) BOOL acceptGzip;

// How are timeouts, retries, and redirects handled?
@property (nonatomic) double                timeoutSeconds;
@property (nonatomic) unsigned              numRetries;
@property (nonatomic) double                retryDelaySeconds;
@property (nonatomic) NKRetryDelayPolicy    retryDelayPolicy;
@property (nonatomic) NKRedirectRetryPolicy redirectRetryPolicy;

// Do we allow a cached responses to this URL?  Simpler
// overlay on NSURLRequestCachePolicy.  Defaults to FALSE.
@property (nonatomic) BOOL allowCachedResponses;

// Default and copy constructors:
-(NKCallBehaviorURLRequest*) init;
-(NKCallBehaviorURLRequest*) init:(NKCallBehaviorURLRequest*)base;

@end
