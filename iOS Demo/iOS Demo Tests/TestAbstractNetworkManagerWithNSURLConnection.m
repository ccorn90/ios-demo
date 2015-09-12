//
//  TestDemoNetworkManager.m
//  iOS Demo
//
//  Created by Christopher Cornelius on 9/7/15.
//
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "NetworkManagerEnums.h"
#import "DemoNetworkManager.h"
#import "OverrideURLConnectionTester.h"
#import "NKNetworkManager.h"

@interface TestAbstractNetworkManagerWithNSURLConnection : XCTestCase <OverrideURLConnectionTesterDelegate, NetworkManagerDelegate>

@property (nonatomic, retain) id<AbstractNetworkManager> networkManager;

// These are different values that need to be given to networkManager in callbacks from
// the OverrideURLConnectionTesterDelegate method:
@property (nonatomic, retain) NSHTTPURLResponse* response;
@property (nonatomic, retain) NSString* urlString;

@property (nonatomic, retain) NSData* expectedData;


// These control the flow of callbacks:
@property (nonatomic) BOOL expectingCallbacks;


@end

@implementation TestAbstractNetworkManagerWithNSURLConnection

- (void)setUp {
    [super setUp];
    
    // Test the networkManager type that you want here:
    self.networkManager = [[DemoNetworkManager alloc] init];

    // This figures out if the network manager type can be tested:
    BOOL canTest = [self.networkManager overrideTestingURLConnectionClass:[OverrideURLConnectionTester class]];
    if(!canTest) {
        XCTFail(@"CANNOT TEST: overrideTestingURLConnectionClass returned FALSE - could not set OverrideURLConnectionTester as the NSURLConnection class to use.");
    }
    
    // We'll set the global delegate for OverrideURLConnectionTester to this object:
    [OverrideURLConnectionTester setTestingDelegate:self];
    
    // Do any other set up we need:
    self.urlString = @"http://www.apple.com";
    self.expectedData = [[NSString stringWithFormat:@"OK!"] dataUsingEncoding:NSASCIIStringEncoding];
    self.expectingCallbacks = TRUE;
}

- (void)tearDown {
    [super tearDown];
    self.networkManager = nil;
    
    // Now clear this out:
    [OverrideURLConnectionTester setTestingDelegate:nil];
}


-(void) testGetCall {
    
    self.response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:self.urlString] statusCode:200 HTTPVersion:@"1.1" headerFields:[NSDictionary dictionary]];
    
    // run the call:
    [self.networkManager get:@"http://www.apple.com" delegate:self context:self];
}

-(void) testNilURL {
    [self.networkManager get:@"" delegate:self context:self];
}



#pragma mark - Callbacks from the OverrideURLConnectionTester

-(void) overrideConnectionWasInitialized:(OverrideURLConnectionTester*)connection {
    // do nothing
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

-(BOOL) overrideConnectionWasScheduled:(OverrideURLConnectionTester*)connection {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return FALSE;
}

-(BOOL) overrideConnectionWasStarted:(OverrideURLConnectionTester*)connection {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // What should happen here is that the callback of loaded header should be given:
    [connection.delegate connection:connection didReceiveResponse:self.response];
    [connection.delegate connection:connection didReceiveData:self.expectedData];
    [connection.delegate connectionDidFinishLoading:connection];
    return FALSE;
}






#pragma mark - Callbacks as NetworkManagerDelegate

-(void) networkManager:(id<AbstractNetworkManager>)networkManager didStartCall:(id)context {
    [self checkContext:context andManager:networkManager];
}


-(void) networkManager:(id<AbstractNetworkManager>)networkManager didRedirectForContext:(id)context
                newURL:(NSString*)newURL httpStatus:(int)httpStatus {
    [self checkContext:context andManager:networkManager];

}


-(void) networkManager:(id<AbstractNetworkManager>)networkManager didLoadHeader:(id)context
                  size:(int)size headers:(NSDictionary*)allHeaderFields {
    [self checkContext:context andManager:networkManager];

}

-(void) networkManager:(id<AbstractNetworkManager>)networkManager didSucceed:(id)context data:(NSData*)data {
    [self checkContext:context andManager:networkManager];
    
    XCTAssertEqualObjects(data, self.expectedData);
    
    
}

-(void) networkManager:(id<AbstractNetworkManager>)networkManager didFail:(id)context
                 error:(NetworkManagerError)errorType httpStatus:(int)httpStatus data:(NSData*)data {
    [self checkContext:context andManager:networkManager];

}

-(void) networkManager:(id<AbstractNetworkManager>)networkManager didFinish:(id)context {
    [self checkContext:context andManager:networkManager];

}

// Helper to verify basic things:
-(void) checkContext:(id)context andManager:(id<AbstractNetworkManager>)networkManager {
    XCTAssertTrue(self.expectingCallbacks, @"Was not expecting NetworkManagerDelegate callbacks for this test.");
    XCTAssertEqual(networkManager, self.networkManager);
    XCTAssertEqual(context, self);
}


@end
