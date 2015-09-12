//
//  NKURLConnectionBridgeTests.m
//  iOS Demo
//
//  Created by Christopher Cornelius on 9/7/15.
//
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "NKURLConnectionBridge.h"


// Tags for the various functions to test:
const int kStartFunc        = 1;
const int kScheduleFunc     = 2;
const int kCancelFunc       = 3;


@interface NKURLConnectionBridgeTests : XCTestCase

@property (nonatomic, retain) id<NKURLConnectionBridge> bridge;

@end


@interface DummyNSURLConnection : NSURLConnection {
    void (^_handlerBlock)(int);
}
@end

@implementation DummyNSURLConnection

-(DummyNSURLConnection*) initWithHandler:(void (^)(int))handlerBlock {
    if(self = [super init]) {
        _handlerBlock = handlerBlock;
    }
    return self;
}

-(void) start {
    _handlerBlock(kStartFunc);
}

-(void) scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    _handlerBlock(kScheduleFunc);
}

-(void) cancel {
    _handlerBlock(kCancelFunc);
}

@end


@implementation NKURLConnectionBridgeTests

- (void)setUp {
    [super setUp];
    
    // INSTANTIATE THIS BRIDGE WITH WHATEVER SUBCLASS YOU NEED TO TEST:
    self.bridge = [[NKDefaultURLConnectionBridge alloc] init];
}

- (void)tearDown {
    [super tearDown];
    self.bridge = nil;
}

-(void) testGetConnection {
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    NSURLConnection* connection = [self.bridge getConnection:request delegate:self startImmediately:FALSE];
    
    XCTAssertTrue([connection isKindOfClass:[NSURLConnection class]]);
}

-(void) testScheduleConnection {
    __block int didCallHandler = -1;
    DummyNSURLConnection* connection = [[DummyNSURLConnection alloc] initWithHandler:^(int k){
        didCallHandler = k;
    }];

    [self.bridge scheduleConnection:connection inRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    XCTAssert(didCallHandler == kScheduleFunc, @"scheduleConnection method must call equivalent method on NSURLConnection!");
}

-(void) testStartConnection {
    __block int didCallHandler = -1;
    DummyNSURLConnection* connection = [[DummyNSURLConnection alloc] initWithHandler:^(int k){
        didCallHandler = k;
    }];
    
    [self.bridge startConnection:connection];
    XCTAssert(didCallHandler == kStartFunc, @"startConnection method must call equivalent method on NSURLConnection!");
}

-(void) testCancelConnection {
    __block int didCallHandler = -1;
    DummyNSURLConnection* connection = [[DummyNSURLConnection alloc] initWithHandler:^(int k){
        didCallHandler = k;
    }];
    
    [self.bridge cancelConnection:connection];
    XCTAssert(didCallHandler == kCancelFunc, @"cancelConnection method must call equivalent method on NSURLConnection!");
}


/* 
 -(NSURLConnection*) getConnection:(NSURLRequest*)request delegate:(id)delegate startImmediately:(BOOL)startImmediately;
 -(void) scheduleConnection:(NSURLConnection*)connection inRunLoop:(NSRunLoop*)runLoop forMode:(NSString*)mode;
 -(void) startConnection:(NSURLConnection*)connection;
 -(void) cancelConnection:(NSURLConnection*)connection;
 */

@end
