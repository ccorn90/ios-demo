//
//  AbstractDataObjectManager.m
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

#import "AbstractDataObjectManager.h"

@implementation AbstractDataObjectManager
@synthesize coordinator = _coordinator, entity = _entity;

-(NSManagedObject*) get:(NSString*)idstr {
    [NSException raise:@"AbstractMethodNotOverridden" format:@"You must override this method!"];
    return nil;
}

-(NSManagedObject*) create:(NSString*)idstr {
    [NSException raise:@"AbstractMethodNotOverridden" format:@"You must override this method!"];
    return nil;
}

-(void) deleteObj:(NSManagedObject*)obj {
    [NSException raise:@"AbstractMethodNotOverridden" format:@"You must override this method!"];
}

-(NSArray*) getWithPredicate:(NSPredicate*)predicate sortBy:(NSSortDescriptor*)sortDescriptor {
    NSArray* arr = nil;
    if(self.coordinator != nil) {
        arr = [self.coordinator fetchManagedObjects:self.entity withPredicate:predicate withSortDescriptor:sortDescriptor];
    }
    return arr;
}

-(AbstractDataObjectManager*) initWithCoreDataCoordinator:(id<AbstractCoreDataCoordinator>)coordinator withEntity:(NSEntityDescription*)entity {
    if(self = [super init]) {
        _coordinator = coordinator;
        _entity      = entity;
    }
    return self;
}

@end
