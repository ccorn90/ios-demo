//
//  NKURLConnectionBridge.h
//  iOS Demo
//
//  Created by Christopher Cornelius on 9/7/15.
//

/** Serves NKNetworkManager by providing an interface to create and control
    NSURLConnection objects.  This allows easy module substitution for testing.  */

#import <Foundation/Foundation.h>


@protocol NKURLConnectionBridge <NSObject>

-(NSURLConnection*) getConnection:(NSURLRequest*)request delegate:(id)delegate startImmediately:(BOOL)startImmediately;
-(void) scheduleConnection:(NSURLConnection*)connection inRunLoop:(NSRunLoop*)runLoop forMode:(NSString*)mode;
-(void) startConnection:(NSURLConnection*)connection;
-(void) cancelConnection:(NSURLConnection*)connection;

@end


@interface NKDefaultURLConnectionBridge : NSObject <NKURLConnectionBridge>

-(NSURLConnection*) getConnection:(NSURLRequest*)request delegate:(id)delegate startImmediately:(BOOL)startImmediately;
-(void) scheduleConnection:(NSURLConnection*)connection inRunLoop:(NSRunLoop*)runLoop forMode:(NSString*)mode;
-(void) startConnection:(NSURLConnection*)connection;
-(void) cancelConnection:(NSURLConnection*)connection;

@end
