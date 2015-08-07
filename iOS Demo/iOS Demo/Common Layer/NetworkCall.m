//
//  NetworkCall.m
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

#import "NetworkCall.h"

@implementation NetworkCall
@synthesize manager = _manager, delegate = _delegate, delegateContext = _delegateContext, urlString = _urlString,
            numRetries = _numRetries, maxRetries = _maxRetries, timeout = _timeout, connection = _connection, data = _data;

-(NetworkCall*) initWithManager:(DemoNetworkManager*)manager delegate:(id<NetworkManagerDelegate>)delegate delegateContext:(id)delegateContext timeout:(double)timeout maxRetries:(int)maxRetries {
    if(self = [super init]) {
        self.manager = manager;
        self.delegate = delegate;
        self.delegateContext = delegateContext;
        self.timeout = timeout;
        self.maxRetries = maxRetries;
        
        // And initialize as needed:
        self.connection = nil;
        self.urlString = nil;
        self.data = [[NSMutableData alloc] init];
        self.request = nil;
        self.runLoop = nil;
        self.numRetries = 0;
    }
    return self;
}

// TASK: This method requires us to call a specific method on NSURLConnection to handle the auth challenge.  I'm leaving
// this out for now to keep the scope of this demo reasonable.  But there are some cases where this can trip up
// an advanced network interchange (it will sometimes default to cached credentials which are out of date).
// - (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

// TASK: In situations where infinite redirects happen, or (more likely) a different redirect happens each time the URL
// is called (for example with some immature loadbalancing schemes) this is the only point to reliably intercept the redirect.
// I'm not implementing anything right now to keep the scope of this demo down but at least I've made the note.  Ideally, we'd
// update the URLString to the final destination if it's a 301 redirect.
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    // For now, just proceed with the redirect.
    return request;
}

// Loaded header.  We need to block in all of these callbacks to the manager because our NSURLConnection
// might get cleared during the call into the manager (I know, I know, that's not a great way to structure
// this.  It's a demo, so I'll take the strategy of acknowledging that shortcoming instead of fixing it right now).
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    @synchronized (self) {
        if(connection == self.connection) {
            [self.manager networkCall:self didRecieveResponse:response];
        }
    }
}

// Loaded some data (this needs to be appended to the store of all recieved data).
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    @synchronized (self) {
        if(connection == self.connection) {
            [self.data appendData:data];
        }
    }
}

// Called when the connection succeeds.
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    @synchronized (self) {
        if(connection == self.connection) {
            [self.manager networkCallDidFinishLoading:self];
        }
    }
}

// Called on failures.
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    @synchronized (self) {
        if(connection == self.connection) {
            [self.manager networkCall:self didFailWithError:error];
        }
    }
}

@end

