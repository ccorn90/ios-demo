//
//  OverrideURLConnectionTester.m
//  iOS Demo
//
//  Created by Christopher Cornelius on 9/7/15.
//
//

#import "OverrideURLConnectionTester.h"
#import "Logging.h"

@interface OverrideURLConnectionTester () {
    NSString* LOGTAG;
}

@property (nonatomic, weak) id delegate;

@end

static id<OverrideURLConnectionTesterDelegate> __overrideURLConnectionTesterTestingDelegate = nil;

@implementation OverrideURLConnectionTester

+(void) setTestingDelegate:(id<OverrideURLConnectionTesterDelegate>)testingDelegate {
    // In this case, @synchronized on self means we're synchronizing on the CLASS.
    // Weird way of saying that, but it works to make this singular.
    @synchronized (self) {
        if(testingDelegate != nil && __overrideURLConnectionTesterTestingDelegate != nil) {
            LogWTF(@"FATAL: tried setting new global testing delegate for OverrideURLConnectionTester when testing delegate is already non-nil!  Did you make a mistake?");
        } else {
            __overrideURLConnectionTesterTestingDelegate = testingDelegate;
        }
    }
}

-(id) initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        LOGTAG = @"OverrideURLConnectionTester";
    });
    
    // initialize the new connection:
    if(self = [super initWithRequest:request delegate:delegate startImmediately:startImmediately]) {
        // capture the delegate:
        self.delegate = delegate;
        
        // Report the initilization to the delegate (this is guarded for nil delegate):
        [__overrideURLConnectionTesterTestingDelegate overrideConnectionWasInitialized:self];
    }
    return self;
}

-(void) scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    if([__overrideURLConnectionTesterTestingDelegate overrideConnectionWasScheduled:self]) {
        [super scheduleInRunLoop:aRunLoop forMode:mode];
    }
}

-(void) start {
    if([__overrideURLConnectionTesterTestingDelegate overrideConnectionWasStarted:self]) {
        [super start];
    }
}

@end
