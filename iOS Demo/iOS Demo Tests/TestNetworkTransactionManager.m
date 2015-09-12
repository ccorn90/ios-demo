//
//  TestNetworkTransactionManager.m
//  iOS Demo
//
//  Created by Christopher Cornelius on 9/7/15.
//
//

#import <XCTest/XCTest.h>
#import "AbstractNetworkManager.h"
#import "NetworkManagerEnums.h"
#import "NetworkTransactionManager.h"
#import "JSONHelpers.h"

@interface TestNetworkTransactionManager : XCTestCase <AbstractNetworkManager, NetworkTransactionManagerDelegate>

@property (nonatomic, retain) NetworkTransactionManager* transactionManager;

@property (nonatomic, retain) NSString* expectedRequestType;
@property (nonatomic, retain) NSString* expectedURLString;
@property (nonatomic, retain) NSDictionary* expectedBodyData;
@property (nonatomic, retain) NSDictionary* expectedReturnData;

// Set this to TRUE in test cases that ought to test a failure:
@property (nonatomic) BOOL failCall;

// Set this to TRUE when you want to cancel the call prematurely:
@property (nonatomic) BOOL cancelCallInTheMiddle;

@end

@implementation TestNetworkTransactionManager

- (void)setUp {
    [super setUp];
    self.transactionManager = [[NetworkTransactionManager alloc] initWithNetworkManager:self];
    self.expectedReturnData = [NSDictionary dictionaryWithObjectsAndKeys:@"one", @"1", [NSNumber numberWithInt:2], @"2" , nil];
    self.expectedBodyData = [NSDictionary dictionaryWithObjectsAndKeys:@"send1", @"send", nil];
    self.expectedURLString   = @"dummyURL";
    self.failCall = FALSE;
    self.cancelCallInTheMiddle = FALSE;
}

- (void)tearDown {
    [super tearDown];
    self.expectedRequestType = nil;
    self.expectedURLString   = nil;
    self.transactionManager  = nil;
}

/* Test the manager for proper returning of delegate and block callbacks. */
-(void) testGetURIDelegateCallbackSucceed { [self helperTestDelegateFailure:FALSE method:@"GET"];  }
-(void) testPutURIDelegateCallbackSucceed { [self helperTestDelegateFailure:FALSE method:@"POST"]; }
-(void) testGetURIDelegateCallbackFailure { [self helperTestDelegateFailure:TRUE  method:@"GET"];  }
-(void) testPutURIDelegateCallbackFailure { [self helperTestDelegateFailure:TRUE  method:@"POST"]; }
-(void) testGetURIBlockCallbackSucceed { [self helperTestBlockFailure:FALSE method:@"GET"];  }
-(void) testPutURIBlockCallbackSucceed { [self helperTestBlockFailure:FALSE method:@"POST"]; }
-(void) testGetURIBlockCallbackFailure { [self helperTestBlockFailure:TRUE  method:@"GET"];  }
-(void) testPutURIBlockCallbackFailure { [self helperTestBlockFailure:TRUE method:@"POST"];  }

// This helper allows the above methods to test delegate callbacks
-(void) helperTestDelegateFailure:(BOOL)failcall method:(NSString*)method {
    self.expectedRequestType = method;
    self.failCall = failcall;
    if([method isEqualToString:@"GET"]) {
        [self.transactionManager get:self.expectedURLString withData:self.expectedBodyData delegate:self context:self];
    } else {
        [self.transactionManager post:self.expectedURLString withData:self.expectedBodyData delegate:self context:self];
    }
}

// This helper allows the above methods to test block callbacks
-(void) helperTestBlockFailure:(BOOL)failcall method:(NSString*)method {
    self.expectedRequestType = method;
    self.failCall = failcall;
    if([method isEqualToString:@"GET"]) {
        [self.transactionManager get:self.expectedURLString withData:self.expectedBodyData success:^(NSDictionary *jsonData) {
            [self networkTransactionManager:self.transactionManager didSucceed:self jsonData:jsonData];
        } failure:^(NetworkManagerError networkError, int httpStatus, BOOL jsonError, NSDictionary *jsonData) {
            [self networkTransactionManager:self.transactionManager didFail:self networkError:networkError httpStatus:httpStatus jsonDecodingFailure:jsonError jsonData:jsonData rawData:nil];
        }];
    } else {
        [self.transactionManager post:self.expectedURLString withData:self.expectedBodyData success:^(NSDictionary *jsonData) {
            [self networkTransactionManager:self.transactionManager didSucceed:self jsonData:jsonData];
        } failure:^(NetworkManagerError networkError, int httpStatus, BOOL jsonError, NSDictionary *jsonData) {
            [self networkTransactionManager:self.transactionManager didFail:self networkError:networkError httpStatus:httpStatus jsonDecodingFailure:jsonError jsonData:jsonData rawData:nil];
        }];
    }
}


// Test the cancel call method - no callbacks should be returned after cancel is sent (see startNetworkCall)
-(void) testCancelCall {
    self.cancelCallInTheMiddle = TRUE;
    [self helperTestDelegateFailure:FALSE method:@"GET"];
}

// Test the network manager accessor
-(void) testNetworkManagerAccessor {
    XCTAssertEqual(self, self.transactionManager.networkManager);
}


// This callback should be called during all the success tests above.
// It shouldn't during a failure test and shouldn't be called during
// the cancel test.  It should return the correct context and json.
-(void) networkTransactionManager:(NetworkTransactionManager*)manager
                       didSucceed:(id)context
                         jsonData:(NSDictionary*)jsonData {
    XCTAssertFalse(self.cancelCallInTheMiddle);
    XCTAssertFalse(self.failCall);
    XCTAssertEqual(self, context);
    XCTAssertEqualObjects(self.expectedReturnData, jsonData, @"NetworkTransactionManager should 100%% properly parse returned JSON.");
    
}

// This callback should be called only during the failure tests.
// It shouldn't during a failure test and shouldn't be called during
// the cancel test.  It should return the correct context and json.
// It should also return a 404 which is NetworkManagerErrorBadRequest.
-(void) networkTransactionManager:(NetworkTransactionManager*)manager
                          didFail:(id)context
                     networkError:(NetworkManagerError)networkError
                       httpStatus:(int)httpStatus
              jsonDecodingFailure:(BOOL)jsonError
                         jsonData:(NSDictionary*)jsonData
                          rawData:(NSData*)rawData {
    
    XCTAssertFalse(self.cancelCallInTheMiddle);
    XCTAssertTrue(self.failCall);
    XCTAssertEqual(self, context);
    XCTAssertEqual(httpStatus, 404);
    XCTAssertEqual(networkError, NetworkManagerErrorBadRequest);
    XCTAssertFalse(jsonError);
    XCTAssertEqualObjects(self.expectedReturnData, jsonData, @"NetworkTransactionManager should 100%% properly parse returned JSON.");
}



// This method tests to make sure that all call-ins from NetworkTransactionManager are type-appropriate
-(NSMutableURLRequest*) buildURLRequest:(NSString*)urlString forRequestType:(NSString*)requestType {
    
    // Ensure that NetworkTransactionManager calls with the proper urlString and requestType:
    XCTAssertTrue([urlString isEqualToString:self.expectedURLString], @"NetworkTransactionManager must build a URLRequest with the same URL as given. %@, expected %@", urlString, self.expectedURLString);
    XCTAssertTrue([requestType isEqualToString:self.expectedRequestType], @"NetworkTransactionManager must build a URLRequest with the same request type as given. %@, expected %@", requestType, self.expectedRequestType);
    
    NSMutableURLRequest* url = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    url.HTTPMethod = requestType;
    
    return url;
}

// Pretends to be a network manager:
-(void) startNetworkCall:(NSMutableURLRequest*)request
            withDelegate:(id<NetworkManagerDelegate>)delegate
            onMainThread:(BOOL)onMainThread
             withTimeout:(double)timeout
          withNumRetries:(unsigned)numRetries
             withContext:(id)context {

    XCTAssertEqual(self.transactionManager, delegate, @"NetworkTransactionManager should specify self as delegate for all network calls.");
    XCTAssert(onMainThread, @"NetworkTransactionManager should run all calls on main thread.");
    XCTAssertNotNil(context, @"NetworkTransactionManager should not use nil context.");
    
    
    // The NetworkTransactionManager should send the expected body data in JSON format:
    XCTAssertEqualObjects(request.HTTPBody, [JSONHelpers toData:self.expectedBodyData], @"NetworkTransactionManager should implicitly send HTTP body data");
    
    // We'll be returning the following dummy data:
    NSData* content = [JSONHelpers toData:self.expectedReturnData];
    
    
    // StartCall:
    if([delegate respondsToSelector:@selector(networkManager:didStartCall:)]) {
        [delegate networkManager:self didStartCall:context];
    }
    
    // DidRedirect:
    if([delegate respondsToSelector:@selector(networkManager:didRedirectForContext:newURL:httpStatus:)]) {
        [delegate networkManager:self didRedirectForContext:context newURL:request.URL.absoluteString httpStatus:301];
    }
    
    // DidLoadHeader:
    XCTAssert([delegate respondsToSelector:@selector(networkManager:didLoadHeader:size:headers:)]);
    [delegate networkManager:self didLoadHeader:context size:(int)content.length headers:nil];
    
    
    // This is the interrupt point where we cancel the call:
    if(self.cancelCallInTheMiddle) {
        [self.transactionManager cancelFromDelegate:self withContext:self];
    }
    
    
    // DidFail: and didSucceed:
    if(self.failCall) {
        [delegate networkManager:self didFail:content error:NetworkManagerErrorBadRequest httpStatus:404 data:content];
    } else {
        [delegate networkManager:self didSucceed:context data:content];
    }
    
    // DidFinish:
    if([delegate respondsToSelector:@selector(networkManager:didFinish:)]) {
        [delegate networkManager:self didFinish:context];
    }
}

@end
