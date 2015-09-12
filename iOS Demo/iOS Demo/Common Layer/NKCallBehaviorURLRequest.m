//
//  NKCallBehaviors.m
//  iOS Demo
//
//  Created by Christopher Cornelius on 9/3/15.
//
//

#import "NKCallBehaviorURLRequest.h"

@implementation NKCallBehaviorURLRequest

-(NKCallBehaviorURLRequest*) init {
    if(self = [super init]) {
        self.priority = NKCallPriorityMedium;
        self.callbackThread = nil;
        self.acceptGzip = TRUE;
        self.timeoutSeconds = 8.0;
        self.numRetries = 3;
        self.retryDelaySeconds = 1.0;
        self.retryDelayPolicy = NKRetryDelayPolicyFixedInterval;
        self.redirectRetryPolicy = NKRedirectRetryPolicyRetryFromTopURL;
        self.allowCachedResponses = FALSE;
    }
    return self;
}
-(NKCallBehaviorURLRequest*) init:(NKCallBehaviorURLRequest*)base {
    if(self = [super init]) {
        self.priority = base.priority;
        self.callbackThread = base.callbackThread;
        self.acceptGzip = base.acceptGzip;
        self.timeoutSeconds = base.timeoutSeconds;
        self.numRetries = base.numRetries;
        self.retryDelaySeconds = base.retryDelaySeconds;
        self.retryDelayPolicy = base.retryDelayPolicy;
        self.redirectRetryPolicy = base.redirectRetryPolicy;
        self.allowCachedResponses = base.allowCachedResponses;
    }
    return self;
}

@end
