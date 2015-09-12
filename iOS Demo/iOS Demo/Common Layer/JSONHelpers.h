//
//  JSONHelpers.h
//  iOS Demo
//
//  Created by Christopher Cornelius on 9/2/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface JSONHelpers : NSObject

// These are very basic encode/decode methods, with enough wrapping to make it
// all work.  They return nil if there was an error.
+(NSData*) toData:(NSDictionary*)json;
+(NSDictionary*) toJSON:(NSData*)data;


// This method allows you to quickly update a bunch of values on an NSManagedObject from a JSON dictionary,
// as long as the keys are exactly the same on the NSManagedObject as they are in the JSON.  Returns TRUE
// if there was a change to object, FALSE if there were no updates.  Remember that this only works for primitives!
+(BOOL) populateViaKeyValueComparison:(NSManagedObject*)object fromJSON:(NSDictionary*)json keys:(NSSet*)keys;


@end
