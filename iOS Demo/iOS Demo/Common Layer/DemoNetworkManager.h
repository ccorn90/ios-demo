//
//  DemoNetworkManager.h
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

/** A demo NetworkManager that does a fair amount of what is ideal in a network manager for mobile.
    It implements all the methods in AbstractNetworkManager and tracks retries and basic statistics.
    It does NOT assign or track priorities and there is no gating, so it's still possible for a
    traffic jam where some calls just hang and die... for example if you were to make 1000 different
    calls at the same time.  If there are too many calls then: (a) latency goes through the roof and
    many things take forever to load, and (b) some calls will actually stall and never send callbacks
    again.  The same thing happens in areas of spotty network connection - so a maintenance timer is
    used to cancel and retry calls that are taking too long. */

#import <Foundation/Foundation.h>
#import "AbstractNetworkManager.h"
#import "NetworkManagerStatistics.h"
@class NetworkCall;

@interface DemoNetworkManager : NSObject <AbstractNetworkManager>

// Returns the current statistics of this NetworkManager:
-(NetworkManagerStatistics*) currentStatistics;

// These are implemented from AbstractNetworkManager:
-(void) get:(NSString*)urlString  delegate:(id<NetworkManagerDelegate>)delegate context:(id)context;
-(void) post:(NSString*)urlString delegate:(id<NetworkManagerDelegate>)delegate context:(id)context data:(NSData*)data;
-(NSMutableURLRequest*) buildURLRequest:(NSString*)urlString;
-(void) startNetworkCall:(NSMutableURLRequest*)request
            withDelegate:(id<NetworkManagerDelegate>)delegate
            onMainThread:(BOOL)onMainThread
             withTimeout:(double)timeout
          withNumRetries:(unsigned)numRetries
             withContext:(id)context;
-(void) cancelForDelegate:(id<NetworkManagerDelegate>)delegate withContext:(id)context;


// Methods for NetworkCall to call (see NetworkCall.h):
-(void) networkCall:(NetworkCall*)call didRecieveResponse:(NSURLResponse*)response;
-(void) networkCallDidFinishLoading:(NetworkCall*)call;
-(void) networkCall:(NetworkCall*)call didFailWithError:(NSError*)error;

@end
