//
//  NKURLConnectionBridge.m
//  iOS Demo
//
//  Created by Christopher Cornelius on 9/7/15.
//
//

#import "NKURLConnectionBridge.h"

@implementation NKDefaultURLConnectionBridge


-(NSURLConnection*) getConnection:(NSURLRequest*)request delegate:(id)delegate startImmediately:(BOOL)startImmediately {
    return [[NSURLConnection alloc] initWithRequest:request delegate:delegate startImmediately:startImmediately];
}


-(void) scheduleConnection:(NSURLConnection*)connection inRunLoop:(NSRunLoop*)runLoop forMode:(NSString*)mode {
    [connection scheduleInRunLoop:runLoop forMode:mode];
}

-(void) startConnection:(NSURLConnection*)connection {
    [connection start];
}

-(void) cancelConnection:(NSURLConnection*)connection {
    [connection cancel];
}

@end
