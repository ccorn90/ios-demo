//
//  AbstractRemoteFetchExecutor.h
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

/** RemoteFetchExecutors are the bridge between a remote object (via a RESTful or semi-REST
    service) and an NSManagedObject. On construction, provide an AbstractDataObjectManager
    and a URL for the requests to go to.  Subclass this abstract base class to provide an
    implementation for each type of object you want to map to a local NSManagedObject subclass.
 
    Note that this would be much different if Objective-C were a naturally template-aware language.
 
    The difference between RemoteFetchExecutors and the raw NetworkTransactionManager is
    entirely about whether the call is directly tracked by the delegate or not.  With a
    subclass of AbstractRemoteFetchExecutor, you ask it to update the data for objects of
    its given type.  The RemoteFetchExecutor will call to the server immediately if you
    specify "force".  If you do not specify "force", the Executor will refresh or update only
    once a preset threshold of objects is reached, or a cyclic timer runs out.
 
    When a fetch is performed, the RemoteFetchExecutor will perform a bulk fetch if more
    than one object is waiting to be updated.  Fetching single object will go against a
    different URL.  Subclassers will handle specific behavior of the RESTful or semi-RESTful
    service by overriding the buildURLRequest: method.
 
 
    Some assumptions here:
        - A get request returns one or several objects depending on the URL endpoint.
        - All objects in this system have an NSString-compatible "ID" field which we
            can use to index our access to the remote server.  This is important because
            we can't pass in an NSManagedObject for fetching if it doesn't exist yet.
            The field doesn't have to be called "id" but it needs to be a string.
 
 
    WHEN YOU SUBCLASS AbstractRemoteFetchExecutor:
        - Override buildURLRequest to set up the NSMutableURLRequest
        - Override processReturnedData to interpret the JSON response (already decoded
            via NetworkTransactionManager).  This is where you will accomodate the specific
            responses returned by the backend server (for example, some servers may return
            both lists of objects and single objects.
        - Override processJSONToObject: to properly upsert an returned object via the
                AbstractDataObjectManager. Return TRUE if there were changes.
        - Add any helper methods that you want. */

#import <Foundation/Foundation.h>
#import "AbstractDataObjectManager.h"
#import "NetworkTransactionManager.h"

// When you request an update, pass one of these handlers - it will return when an object
// update call succeeds and tell you which objects were updated.
typedef void (^onFetchHandler)(NSSet* updatedObjects);

@interface AbstractRemoteFetchExecutor : NSObject

-(void) requestUpdateForObjectID:(NSString*)idstring handler:(onFetchHandler)handler;  // implicit force when you call this method
-(void) requestUpdateForObjectsIDs:(NSSet*)idstrings handler:(onFetchHandler)handler force:(BOOL)force;



// Subclassers MUST override this method!  In it, select the correct service to use (singleObjectUpdateURL
// or batchUpdateURL) and build an appropriate NSMutableURLRequest to update/fetch the given objects,
// adding JSON payload and HTTP headers as needed.
-(NSMutableURLRequest*) buildURLRequest:(BOOL)isBatch forObjects:(NSSet*)objectIDs;

// Subclassers MUST override this method!  Return TRUE if the JSON is a valid response for the given HTTP
// code AND if the response is one that would indicate remote success.  For example, a return of
// {"status":"fail"} might be a failure case even though the code is 200.
-(BOOL) isSuccessJSON:(NSDictionary*)json forHTTPCode:(int)httpStatus;

// Subclassers MUST override this method!  If the call is deemed successful, this will be called.
-(BOOL) processSuccessJSON:(NSDictionary*)json;

// These are the URLs called against when the executor performs an update.  If batchUpdateURL
// is specified nil in the constructor, batch fetches will be performed as single fetches.
@property (nonatomic, readonly) NSString* singleObjectUpdateURL;
@property (nonatomic, readonly) NSString* batchUpdateURL;

// These are relevant objects which are held privately and exposed here:
-(NetworkTransactionManager*) networkTransactionManager;
-(NSEntityDescription*) entity;
-(AbstractDataObjectManager*) dataManager;



@end
