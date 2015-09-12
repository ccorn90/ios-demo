//
//  GlobalThreadPool.h
//  iOS Demo
//
//  Created by Christopher Cornelius on 9/9/15.
//

// System for getting and managing threads by an "identifier", which is just a string.
// Useful if you have a bunch of objects that may as well share a thread.

#import <Foundation/Foundation.h>

@interface SharedThreadPool : NSObject

// To get and release a thread, do these things:
-(NSThread*) subscribeToThreadWithIdentifer:(NSString*)threadIdentifier;
-(void)      unsubscribeThreadWithIdentifier:(NSString*)threadIdentifier;

// Indicates that the thread with the given identifier is to be
// used frequently and should not be closed down.
-(void)      pinThread:(BOOL)pinned withIdentifier:(NSString*)threadIdentifier;


// And for people who want a singleton...
+(SharedThreadPool*) singleton;


// This method is for
#ifdef TESTING
-(NSMutableDictionary*) allThreads;
#endif // TESTING


@end
