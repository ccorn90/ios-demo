//
//  AbstractDataObjectManager.h
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

/** AbstractDataObjectManager subclasses are used by the implementing application to oversee
    the access for one NSManagedObject subclass, therefore a data type in the system.  These
    are kind of like ORM helpers that centralize the access to a given CoreData ManagedObject
    type.  There are effectively four core functions that a DataObjectManager performs:
        create:, get-by-id:, delete: and get-with-predicate:.
 
    WHEN YOU SUBCLASS AbstractDataObjectManager:
        - Override the get:, create:, and delete: methods to make them type-strict for the NSManagedObject subclass you're using.
        - In your get: method implementation, call get-with-predicate with an appropriate predicate to search by ID.
        - In your create: method, do a get: to check existance, call createNewObjectOfEntity, and then populate any initial values (like the id!)
        - In your delete: method, break any associations and then call deleteManagedObjectOfEntity: to remove the object.
        - Optionally subclass the getWithPredicate: method if you want to add sugar. */

#import <Foundation/Foundation.h>
#import "AbstractCoreDataCoordinator.h"

@interface AbstractDataObjectManager : NSObject

#pragma mark - Subclassers MUST override these methods!

#pragma mark - Subclasses must NOT override these methods!

-(AbstractDataObjectManager*) initWithCoreDataCoordinator:(id<AbstractCoreDataCoordinator>)coordinator withEntity:(NSEntityDescription*)entity;

@end
