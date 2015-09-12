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
        create:, get-by-id:, deleteObj: and get-with-predicate:.
 
    WHEN YOU SUBCLASS AbstractDataObjectManager:
        - Override the get:, create:, and delete: methods to make them type-strict for the NSManagedObject subclass you're using.
        - In your get: method implementation, call get-with-predicate with an appropriate predicate to search by ID.
        - In your create: method, do a get: to check existance, call createObject:, and then populate any initial values (like the id!)
        - In your deleteObj: method, break any associations and then call deleteObj: to remove the object.
        - Optionally subclass the getWithPredicate: method if you want to add sugar.
        - To be thread-safe for two simultaneous operation for the same id, you'll need to lock on self inside the create and
                delete methods.  Locking in the get method and the get-with-predicate method is optional but suggested.
 */

#import <Foundation/Foundation.h>
#import "AbstractCoreDataCoordinator.h"

@interface AbstractDataObjectManager : NSObject

// Init method -- subclassers may override at will, or call this inside their own "init" method.
-(AbstractDataObjectManager*) initWithCoreDataCoordinator:(id<AbstractCoreDataCoordinator>)coordinator withEntity:(NSEntityDescription*)entity;

// Get the CoreDataCoordinator for this object.
// DO NOT OVERRIDE THIS METHOD!
@property (nonatomic, readonly) id<AbstractCoreDataCoordinator> coordinator;

// This is the entity for this object.  It's the most crucial thing we've got going
// on here.  This defines what type of object this DataManager is responsible for.
// DO NOT OVERRIDE THIS PROPERTY!
@property (nonatomic, readonly) NSEntityDescription* entity;

// Get a ManagedObject by it's ID.
// Subclassers MUST override this method in order to change the return type
// to the appropriate NSManagedObject subclass, and to provide the correct
// predicate for searching by ID.
-(NSManagedObject*) get:(NSString*)idstring;

// Create a new ManagedObject with the given ID.
// Subclassers MUST override this method in order to change the return type to the
// appropriate NSManagedObject subclass, and to provide the correct initialization
// and setup for the object.
-(NSManagedObject*) create:(NSString*)idstring;

// Deletes the given ManagedObject.
// Subclassers MUST override this method in order to change the return type to the
// appropriate NSManagedObjectSubclass and to do any cleanup required.  Inside, you
// should call [self.coordinator deleteObject:] to do the actual delete.
-(void) deleteObj:(NSManagedObject*)obj;

// Runs a request for the given predicate and returns the results.  The implementation
// of this method is almost exactly the same for every type of managed object, so you
// probably don't need to override.
// NOTE: This method does not lock anything, so if you want to lock self while you run
// the request, override this method in subclass and wrap it in a synchronized block.
-(NSArray*) getWithPredicate:(NSPredicate*)predicate sortBy:(NSSortDescriptor*)sortDescriptor;



@end
