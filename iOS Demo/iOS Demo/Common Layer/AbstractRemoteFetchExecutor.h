//
//  AbstractRemoteFetchExecutor.h
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

/** RemoteFetchExecutors are the bridge between a remote object
    (via a RESTful or semi-REST service) and an NSManagedObject.
    On construction, provide an AbstractDataObjectManager and a
    URL for the requests to go to.  Subclass this abstract base
    class to provide an implementation for each type of object
    you want to map to a local NSManagedObject subclass. 
 
    Note that this would be much different if Objective-C were a
    naturally template-aware language.
 
    Some assumptions here:
        - A get request returns one or several objects 
 
 
    WHEN YOU SUBCLASS AbstractRemoteFetchExecutor:
        - Override processReturnedData: to interpret the JSON
            response (already decoded via NetworkTransactionManager).
            This is where you will accomodate the specific responses
            returned by the backend server (for example, some servers
            may return both lists of objects and single objects.
        - Override processJSONToObject: to properly upsert an
            returned object via the AbstractDataObjectManager.
            Return TRUE if there were changes.
        - Add any helper methods that you want. */

#import <Foundation/Foundation.h>

@interface AbstractRemoteFetchExecutor : NSObject

@end
