//
//  OverrideURLConnectionTester.h
//  iOS Demo
//
//  Created by Christopher Cornelius on 9/7/15.
//
//

#import <Foundation/Foundation.h>


// This protocol defines the methods that are called as things progress.  Return TRUE if you
// want the superclass method to be called (in most cases, the delegate will do this itself
// so you'll want to return FALSE.
@class OverrideURLConnectionTester;
@protocol OverrideURLConnectionTesterDelegate <NSObject>

-(void) overrideConnectionWasInitialized:(OverrideURLConnectionTester*)connection;
-(BOOL) overrideConnectionWasScheduled:(OverrideURLConnectionTester*)connection;
-(BOOL) overrideConnectionWasStarted:(OverrideURLConnectionTester*)connection;


@end

@interface OverrideURLConnectionTester : NSURLConnection

+(void) setTestingDelegate:(id<OverrideURLConnectionTesterDelegate>)testingDelegate;

// This exposes the delegate:
-(id) delegate;

// These methods are overridden:
-(id) initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately;
-(void) scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode;
-(void) start;

@end
