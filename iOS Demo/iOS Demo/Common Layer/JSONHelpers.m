//
//  JSONHelpers.m
//  iOS Demo
//
//  Created by Christopher Cornelius on 9/2/15.
//
//

#import "JSONHelpers.h"
#import "Logging.h"

@implementation JSONHelpers

// These return nil if there was an error:
+(NSData*) toData:(NSDictionary*)json {
    NSData* data = nil;
    
    if(json != nil) {
        if(![NSJSONSerialization isValidJSONObject:json]) {
            LogE(@"json", @"\n\n********JSON SERIALIZATION ERROR ***********\n\nGot error serializing JSON object - %@\n\nJSON object is NOT VALID\n\n********JSON SERIALIZATION ERROR ***********\n\n", json);
        }
        else {
            NSError* error = nil;
            
            data = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
            
            if(error != nil || data == nil) {
                LogE(@"json", @"\n\n********JSON SERIALIZATION ERROR ***********\n\nGot error serializing JSON object - %@\n\nJSON object is : %@\n\n********JSON SERIALIZATION ERROR ***********\n\n", error, json);
                data = nil;
            }
        }
    }
    
    return data;
}

+(NSDictionary*) toJSON:(NSData*)data {
    NSDictionary* json = nil;
    
    if(data != nil) {
        NSError* error = nil;
        
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        if(error != nil || json == nil) {
            LogE(@"json", @"\n\n********JSON SERIALIZATION ERROR ***********\n\nGot error deserializing JSON object - %@\n\n********JSON SERIALIZATION ERROR ***********\n\n", error);
            json = nil;
        }
    }
    
    return json;
}


-(BOOL) populateViaKeyValueComparison:(NSManagedObject*)object fromJSON:(NSDictionary*)json keys:(NSSet*)keys {
    BOOL wasChange = FALSE;
    
    if(object == nil || json == nil || keys == nil) {
        LogW(@"json", @"Cannot do key-value population for nil object, json, or keys!");
    } else {
        
        LogD(@"jsonh", @"UPDATING OBJECT %p BY KEY for %u keys.  JSON has %u k-v pairs in total.", object, [keys count], [json count]);
        
        // We'll take advantage of the key-value compliance of NSManagedObject.
        // This only really works for primatives, so be careful!  Pass in the
        // values you want to have automatically merged over from the JSON into
        // the managed object.  This guards on a key-by-key basis for issues.
        for (NSString* key in keys) {
            @try {
                // determine the values - this will throw an exception if
                // object doesn't have a property with the name "key".
                id oldValue = [object valueForKey:key];
                id newValue = [json  valueForKey:key];
                
                if(newValue == nil) {
                    LogW(@"json",@"WARNING: JSON  was missing key %@.  Will not update object for this key.", key);
                } else {
                    
                    // we'll set this either way:
                    [object setValue:newValue forKey:key];
                    
                    // detect if there was a change:
                    if((oldValue == nil && newValue != nil) || ![oldValue isEqual:newValue]) {
                        LogD(@"json", @"UPDATE key %@ : %@ => %@", key, oldValue, newValue);
                        wasChange = TRUE;
                    }
                }
            }
            @catch (NSException *exception) {
                if(exception.name == NSUndefinedKeyException) {
                    // This exception tyoe will be thrown if the key is not defined in the model:
                    LogE(@"json", @"Entity %@ does not have property for key %@ !!  Exception was: %@", object.entity.name, key, exception);
                } else {
                    // In the rare case where some other exception occurrs:
                    LogE(@"json", @"Got unrecognized exception while doing k-v population of object %p, entity %@, key %@.  Exception was: %@.", object, object.entity.name, key, exception);
                }
            }
        }
    }
    
    return wasChange;
}


@end
