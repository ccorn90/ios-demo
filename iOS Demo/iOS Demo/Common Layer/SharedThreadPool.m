//
//  GlobalThreadPool.m
//  iOS Demo
//
//  Created by Christopher Cornelius on 9/9/15.
//
//

#import "SharedThreadPool.h"
#import "Logging.h"
#import <pthread.h>


#pragma mark - Custom NSThread subclass:

// This simple NSThread subclass adds a couple extra properties:
@interface SharedThreadPoolThread : NSThread

// Lifecycle properties:
@property (nonatomic, retain) NSObject* lock;
@property (nonatomic)         BOOL threadShouldRun;
@property (nonatomic, retain) NSTimer* keepAliveTimer;

// Statistics properties:
@property (nonatomic) long threadIndex;
@property (nonatomic) long numberOfSubscribers;
@property (nonatomic, retain) id<NSCopying> identifier;
@property (nonatomic, retain) NSDate* pinExpirationDate;

@end

@implementation SharedThreadPoolThread

@end


#pragma mark - Extras on SharedThreadPool

@interface SharedThreadPool () {
    NSString* LOGTAG;
}

@property (nonatomic) long threadPoolIndex;
@property (nonatomic) long numThreadsCreated;
@property (nonatomic, retain) NSObject* lock;
@property (nonatomic, retain) NSMutableDictionary* allThreads;

// The internal dispatch queue where messages are posted to manage the thread pool:
@property (nonatomic, retain) dispatch_queue_t queue;

@end


#pragma mark - SharedThreadPool lifecycle
@implementation SharedThreadPool

-(SharedThreadPool*) init {
    if(self = [super init]) {
        LOGTAG = @"SharedThreadPool";
        static long numSharedThreadPoolsCreated = 0;
        self.threadPoolIndex = numSharedThreadPoolsCreated++;
        self.numThreadsCreated = 0;
        self.lock = [[NSObject alloc] init];
        self.allThreads = [[NSMutableDictionary alloc] init];
        
        NSString* dispatchQueueName = [NSString stringWithFormat:@"iosdemo.sharedthreadpool.%ld", self.threadPoolIndex];
        self.queue = dispatch_queue_create([[dispatchQueueName dataUsingEncoding:NSASCIIStringEncoding] bytes], NULL);
    }
    return self;
}


-(void) dealloc {
    // We don't need to release our internal dispatch queue because of ARC, but it's
    // important to remember what we ought to have done here: dispatch_release(self.queue);
}


#pragma mark - Thread main loop:

// This method does nothing and is the firing point for
// the keepAliveTimer on each thread in the pool.
-(void) doNothing { }


// This method is the main loop for the threads.
// Multiple threads can call it - that's just fine:
-(void) threadMainLoop:(NSString*)identifier {
    SharedThreadPoolThread* thread = nil;
    @synchronized (self.lock) {
        thread = [self.allThreads objectForKey:identifier];
        if(thread == nil) {
            LogWTF(@"SharedThreadPool - INTERNAL INCONSISTANCY!  Entered main loop for identifier %@ but could not find thread in map!  Current thread is named %@.", identifier, [NSThread currentThread].name);
        }
    }
    
    // This is the RunLoop associated with local var thread:
    NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
    
    // Set up the name for this thread:
    NSString* threadIdentifierString = (thread.identifier == [NSNull null]) ? @"<default>" : [NSString stringWithFormat:@"%@",thread.identifier];
    NSString* name = [NSString stringWithFormat:@"%@ [%ld.%ld]", threadIdentifierString, self.threadPoolIndex, thread.threadIndex];
    [[NSThread currentThread] setName:name];
    pthread_setname_np([[name dataUsingEncoding:NSASCIIStringEncoding] bytes]);
    
    // Start the keepAliveTimer for this thread, too.  Without a timer, the RunLoop won't run at all, killing the thread instantly.
    @synchronized (thread.lock) {
        thread.keepAliveTimer = [NSTimer timerWithTimeInterval:600.0 target:self selector:@selector(doNothing) userInfo:nil repeats:YES];
        [runLoop addTimer:thread.keepAliveTimer forMode:NSDefaultRunLoopMode];
    }
    
    LogD(LOGTAG, @"Thread started: %@", thread.name);
    
    // This is the main loop for this thread - it runs until thread.threadShouldRun is set to NO.
    // On a turn through the loop, we first update from the thread's thread.threadShouldRun, and
    // then run the run loop for a minute or so.
    BOOL run = TRUE;
    while(run) {
        @synchronized (thread.lock) {
            // If the thread's keepAliveTimer is invalidated, the thread should exit.
            run = thread.threadShouldRun;
            run &= [thread.keepAliveTimer isValid];
        }
        
        run &= [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:60.0]];
    }
    
    // Invalidate this just in case:
    [thread.keepAliveTimer invalidate];
    
    LogD(LOGTAG, @"Thread will exit: %@", thread.name);
}

#pragma mark - User Methods:

+(SharedThreadPool*) singleton {
    static SharedThreadPool* __singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __singleton = [[SharedThreadPool alloc] init];
    });
    
    return __singleton;
}

// To get and release a thread, do these things:
-(NSThread*) subscribeToThreadWithIdentifer:(id)threadIdentifier {
    SharedThreadPoolThread* thread = nil;
    @synchronized (self.lock) {
        thread = [self getThread:threadIdentifier];
        if(thread == nil) {
            thread = [self bootThread:threadIdentifier];
        }
        
        // Increment the number of subscribers for this thread:
        thread.numberOfSubscribers++;
    }
    return thread;
}

-(void) unsubscribeThreadWithIdentifier:(id)threadIdentifier {
    @synchronized (self.lock) {
        SharedThreadPoolThread* thread = [self getThread:threadIdentifier];
        if(thread != nil) {
            // Decrement the number of subscribers for this thread:
            thread.numberOfSubscribers--;
            
            [self checkThreadIdentifier:thread.identifier afterDelay:10.0];
        }
    }
}

// Indicates that the thread with the given identifier is to be
// used frequently and should not be closed down.
-(void)      pinThread:(BOOL)pinned withIdentifier:(id)threadIdentifier {
    @synchronized (self.lock) {
        SharedThreadPoolThread* thread = [self getThread:threadIdentifier];
        thread.pinExpirationDate = pinned ? [NSDate dateWithTimeIntervalSinceNow:300.0] : nil;
        [self checkThreadIdentifier:thread.identifier afterDelay:pinned ? 300.0 : 10.0];
    }
}




#pragma mark - Internal helpers:

-(void) checkThreadIdentifier:(id)identifier afterDelay:(NSTimeInterval)delay {
    // Post a message to the internal dispatch queue requesting
    // that we check if this thread shoud be cleared:
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), self.queue, ^{
        @synchronized (self.lock) {
            SharedThreadPoolThread* thread = [self getThread:identifier];
            if(thread != nil) {
                LogD(LOGTAG, @"Considering clearing thread %@ ... it currently has %ld subscribers and is pinned for date %@", thread.name, thread.numberOfSubscribers, thread.pinExpirationDate);
                if(thread.numberOfSubscribers <= 0 && (thread.pinExpirationDate == nil || [thread.pinExpirationDate timeIntervalSinceNow] < 0.0)) {
                    [self clearThread:thread];
                }
            }
        }
    });
}

-(SharedThreadPoolThread*) getThread:(const id)threadIdentifier {
    // We'll support nil identifiers this way:
    const id identifier = threadIdentifier ?: [NSNull null];
    
    return [self.allThreads objectForKey:identifier];
}

// CALL THIS HELPER FROM A SYNCHRONIZED CONTEXT!!!
-(SharedThreadPoolThread*) bootThread:(id)threadIdentifier {
    // We'll allow nil identifiers in this way:
    const id identifier = threadIdentifier ?: [NSNull null];
    
    // Set up the new thread:
    SharedThreadPoolThread* thread = [[SharedThreadPoolThread alloc] initWithTarget:self selector:@selector(threadMainLoop:) object:identifier];
    thread.lock = [[NSObject alloc] init];
    thread.identifier = [identifier copy];
    thread.threadShouldRun = TRUE;
    thread.numberOfSubscribers = 0;
    [self.allThreads setObject:thread forKey:identifier];
    
    // Copy and increment numThreadsCreated, which tracks how many threads this object has made:
    thread.threadIndex = self.numThreadsCreated++;
    
    // Start the thread:
    [thread start];
    
    return thread;
}

// CALL THIS HELPER FROM A SYNCHRONIZED CONTEXT!!!
-(void) clearThread:(SharedThreadPoolThread*)thread {
    if(thread != nil) {
        [self.allThreads removeObjectForKey:thread.identifier];
        
        @synchronized (thread.lock) {
            LogD(LOGTAG, @"Clearing thread %@", thread.name);
            thread.threadShouldRun = FALSE;
            [thread.keepAliveTimer invalidate];
        }
        
        [self performSelector:@selector(stopForThread:) onThread:thread withObject:thread waitUntilDone:NO];
    }
}

// CALL THIS ON A THREAD IN THE THREAD POOL TO STOP ITS RUNLOOP WAIT:
-(void) stopForThread:(SharedThreadPoolThread*)thread {
    if([NSThread currentThread] == thread) {
        LogD(LOGTAG, @"HALTING RUNLOOP NOW FOR THREAD: %@", thread.name);
        CFRunLoopStop(CFRunLoopGetCurrent());
    }
}






@end
