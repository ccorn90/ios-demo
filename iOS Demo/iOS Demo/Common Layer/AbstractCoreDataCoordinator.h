//
//  AbstractCoreDataCoordinator.h
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

/** A CoreDataCoordinator is an object, created in the application layer, that handles
    CoreData interactions for the app.  Implement this protocol to provide CoreData
    backing to your AbstractDataObjectManager subclasses.  Create one AbstractDataObjectManager
    subclass for each NSManagedObject you will use in the system so you have a simple,
    well-defined system for accessing each type of NSManagedObject.  */

#import <CoreData/CoreData.h>

@protocol AbstractCoreDataCoordinator <NSObject>

// Get an entity description for a given managed object name.  Use this to get the
// proper entity description when you create an AbstractDataObjectManager subclass.
-(NSEntityDescription*) getEntityForName:(NSString*)entityName;

// Create a new object of the given entity:
-(NSManagedObject*) createObject:(NSEntityDescription*)entity;

// Delete the given object:
-(void) deleteObject:(NSManagedObject*)object;

// Run a fetch request for the given objects:
-(NSArray*) fetchManagedObjects:(NSEntityDescription*)entity withPredicate:(NSPredicate*)predicate withSortDescriptor:(NSSortDescriptor*)sortDescriptor;

@end