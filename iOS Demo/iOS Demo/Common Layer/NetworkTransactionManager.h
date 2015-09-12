//
//  NetworkTransactionManager.h
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

/** This manager deals with network TRANSACTIONs, as opposed to network CALLs.
    In this system, a network transaction follows a defined structure and uses
    JSON as the packaging format.  Because of the 1:1 translation possible
    between JSON and an NSDictionary-tree-structure, the NetworkTransactionManager
    is able to speak JSON data to the server and deal with the code of the app
    using NSDictionaries instead.  This permits AbstractRemoteExecutor subclasses
    (coming soon) to do a quick and painless mapping from the data returned from
    a network call and an NSManagedObject subclass in CoreData.
    
    There are two ways that NetworkTransactionManager can handle calls... via
    delegation and via blocks.  See the protocol and block typedefs below.
 
    Subclassers can override the verifyJSON: method to provide additional parsing
    for success/failure.  For example, some servers may return a 200 code but
    indicate a failure in the JSON package.  To go against such a server, override
    verifyJSON: and return the appropriate NetworkManagerError or
    NetworkManagerErrorNoError if all is well. */

#import <Foundation/Foundation.h>
#import "AbstractNetworkManager.h"



#pragma mark - If you like delegation, do it this way.
@class NetworkTransactionManager;
@protocol NetworkTransactionManagerDelegate <NSObject>

// On success, you'll get back the JSON data that was returned:
-(void) networkTransactionManager:(NetworkTransactionManager*)manager
                       didSucceed:(id)context
                         jsonData:(NSDictionary*)jsonData;

// On failure, you'll recieve some information about the failure and some JSON if it was decodable.
-(void) networkTransactionManager:(NetworkTransactionManager*)manager
                          didFail:(id)context
                     networkError:(NetworkManagerError)networkError
                       httpStatus:(int)httpStatus
              jsonDecodingFailure:(BOOL)jsonError
                         jsonData:(NSDictionary*)jsonData
                          rawData:(NSData*)rawData;

@end


#pragma mark - If you prefer blocks, use these!
typedef void (^NetworkTransactionManagerSuccessHandler) (NSDictionary* jsonData);
typedef void (^NetworkTransactionManagerFailureHandler) (NetworkManagerError networkError, int httpStatus, BOOL jsonError, NSDictionary* jsonData);



#pragma mark - The NetworkTransactionManager class
@interface NetworkTransactionManager : NSObject

// Critical information - the network manager to run the calls
-(id<AbstractNetworkManager>) networkManager;
-(NetworkTransactionManager*) initWithNetworkManager:(id<AbstractNetworkManager>)networkManager;

// For delegation.  Callbacks are guaranteed to be asynchronous, and on the main thread.
-(void) get:(NSString*)url withData:(NSDictionary*)jsonData
                           delegate:(id<NetworkTransactionManagerDelegate>)delegate context:(id)context;
-(void) post:(NSString*)url withData:(NSDictionary*)jsonData
                            delegate:(id<NetworkTransactionManagerDelegate>)delegate context:(id)context;
// For block callbacks.  Callbacks are guaranteed to be asynchronous, and on the main thread.
-(void) get:(NSString*)url withData:(NSDictionary*)jsonData
                            success:(NetworkTransactionManagerSuccessHandler)successHandler
                            failure:(NetworkTransactionManagerFailureHandler)failureHandler;
-(void) post:(NSString*)url withData:(NSDictionary*)jsonData
                            success:(NetworkTransactionManagerSuccessHandler)successHandler
                            failure:(NetworkTransactionManagerFailureHandler)failureHandler;

// In case you want to cancel a call:
-(void) cancelFromDelegate:(id<NetworkTransactionManagerDelegate>)delegate withContext:(id)context;


// Helper for subclassers to override if they want JSON content validation to determine success or failure:
-(NetworkManagerError) verifyJSON:(NSDictionary*)json;

@end
