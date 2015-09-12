//
//  TestSharedThreadPool.m
//  iOS Demo
//
//  Created by Christopher Cornelius on 9/11/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "SharedThreadPool.h"


@interface TestSharedThreadPool : XCTestCase {
    NSString* kIdentifier;
}

// This the thread pool under test:
@property (nonatomic, retain) SharedThreadPool* pool;

// This semaphore will allow us to block the main (testing)
// thread while the other things happen on different threads:
@property (nonatomic, retain) dispatch_semaphore_t semaphore;
@property (nonatomic, retain) dispatch_queue_t     queue;
@property (atomic, retain)    NSString* errorStr;

-(void) setErrorValue:(NSString*)error;

@end

/* This function and macro allow us to pass along a failure message if an assert fails asynchronously. */
#define asyncAssertTrue(test, str) (__asyncAssertTrueTestFunc(self, test, (str ?: [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__])))
static void __asyncAssertTrueTestFunc(id obj, BOOL test, NSString* str) {
    if(!test && [obj isKindOfClass:[TestSharedThreadPool class]]) {
        [obj setErrorValue:str];
    }
}

@implementation TestSharedThreadPool

-(void) setErrorValue:(NSString *)error {
    self.errorStr = error;
}

- (void)setUp {
    [super setUp];
    kIdentifier = @"TestingThread";
    self.pool = [[SharedThreadPool alloc] init];
    self.semaphore = dispatch_semaphore_create(0);
    self.queue = dispatch_queue_create("TestSharedThreadPoolQueue", DISPATCH_QUEUE_SERIAL);
    self.errorStr = nil;
}

- (void)tearDown {
    [super tearDown];
    
    // If we weren't in ARC...
    // dispatch_release(self.semaphore);
}

// An NSThread should be returned that stays alive until it is unsubscribed.
-(void) testNilIdentifier {
    [self helperTestThreadSubscribeForIdentifier:nil];
}

-(void) testEmptyStringIdentifier {
    [self helperTestThreadSubscribeForIdentifier:@""];
}

-(void) testStringIdentifier {
    [self helperTestThreadSubscribeForIdentifier:kIdentifier];
}


-(void) helperTestThreadSubscribeForIdentifier:(NSString*)identifier {
    // We need to check against a different key when identifier is nil:
    id checkIdentifier = identifier ?: [NSNull null];
    
    // First, we'll get a thread from the thread pool:
    NSThread* thread = [self.pool subscribeToThreadWithIdentifer:identifier];
    
    asyncAssertTrue([thread isKindOfClass:[NSThread class]], @"Must return a type of NSThread from subscribeToThreadWithIdentifer:");

    // Next, we need to check to see that the thread is alive and then release it:
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), self.queue, ^{
        // Make sure there is a thread with this name:
        asyncAssertTrue(thread == [[self.pool allThreads] objectForKey:checkIdentifier], @"Thread must be kept around under the same key!");
        
        // Unsubscribe:
        [self.pool unsubscribeThreadWithIdentifier:identifier];
        
        // After ten seconds, the thread should have expired and been discontinued:
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(12.0 * NSEC_PER_SEC)), self.queue, ^{
            
            asyncAssertTrue(nil == [[self.pool allThreads] objectForKey:checkIdentifier], @"Released thread must be cleared after 12 seconds!");
            
            // Now release the semaphore so we can continue:
            dispatch_semaphore_signal(self.semaphore);
        });
    });
    
    
    // Wait on the semaphore until the above tasks are done:
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    
    // If we had an error, fail:
    if(self.errorStr != nil) {
        XCTFail(@"%@", self.errorStr);
    }
}

-(void) testThreadPin {
    
    // Subscribe to a thread, pin it, then unsubscribe and ensure it's still around
    NSThread* thread = [self.pool subscribeToThreadWithIdentifer:kIdentifier];
    [self.pool pinThread:YES withIdentifier:kIdentifier];
    asyncAssertTrue([[self.pool allThreads] objectForKey:kIdentifier] == thread, @"Subscribing to a thread should work as intended.");
    
    // unsubscribe, now:
    [self.pool unsubscribeThreadWithIdentifier:kIdentifier];
    
    // Ten seconds after being unsubscribed, the thread should still be around
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(12.0 * NSEC_PER_SEC)), self.queue, ^{
        asyncAssertTrue([[self.pool allThreads] objectForKey:kIdentifier] == thread, @"A pinned thread should persist after unsubscription");
        
        // now unpin
        [self.pool pinThread:FALSE withIdentifier:kIdentifier];
        
        // Ten seconds after being unpinned, the thread should have expired and been discontinued:
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(12.0 * NSEC_PER_SEC)), self.queue, ^{
            
            asyncAssertTrue(nil == [[self.pool allThreads] objectForKey:kIdentifier], @"Released thread must be cleared after 12 seconds!");
            
            // Now release the semaphore so we can continue:
            dispatch_semaphore_signal(self.semaphore);
        });
    });
    
    
    // Wait on the semaphore until the above tasks are done:
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    
    // If we had an error, fail:
    if(self.errorStr != nil) {
        XCTFail(@"%@", self.errorStr);
    }
}



-(void) testAsynchronousExample {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), self.queue, ^{
        dispatch_semaphore_signal(self.semaphore);
    });
    
    // Wait on the semaphore... it will be released in 0.1 seconds by the block above.
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
}

@end
