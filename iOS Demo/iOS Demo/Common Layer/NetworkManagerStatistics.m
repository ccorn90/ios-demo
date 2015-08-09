//
//  NetworkManagerStatistics.m
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

#import "NetworkManagerStatistics.h"
#import "Logging.h"

@implementation NetworkManagerStatistics

-(void) printAll {
    NSMutableString* str = [NSMutableString string];
    
    [str appendFormat:@"Network Manager Snapshot: %@\n", self.date];
    [str appendFormat:@"%llu calls in flight.  %llu are retries.\n", self.numCallsInFlight, self.numRetriesInFlight];
    [str appendFormat:@"Total of %llu failures versus %llu successful calls, with %llu retries.\n", self.totalFailedCalls, self.totalSuccessfulCalls, self.totalNumRetries];
    [str appendFormat:@"Mean average latency is %lf\n", self.meanAverageLatency];
    [str appendFormat:@"Total failures to date by type:\n\tNo Connection: %llu\n\tTimed Out: %llu\n\tBad Request (400): %llu\n\tBad Server (500): %llu\n\tInternal Error: %llu\n",
                        self.failuresNoConnection, self.failuresTimedOut, self.failuresBadRequest,
                        self.failuresBadServer, self.failuresInternalError];
    
    LogW(@"%@",str);
}



-(id) copyWithZone:(NSZone *)zone {
    // Oh, how I yearn for a non-error-prone NSCopyObject function
    // ... or for an IDE that has the "generate copy constructor" method.
    
    NetworkManagerStatistics* new = [[NetworkManagerStatistics alloc] init];
    new.date = [self.date copy];
    new.numCallsInFlight        = self.numCallsInFlight;
    new.numRetriesInFlight      = self.numRetriesInFlight;
    new.failuresNoConnection    = self.failuresNoConnection;
    new.failuresTimedOut        = self.failuresTimedOut;
    new.failuresBadRequest      = self.failuresBadRequest;
    new.failuresBadServer       = self.failuresBadServer;
    new.failuresInternalError   = self.failuresInternalError;
    new.totalFailedCalls        = self.totalFailedCalls;
    new.totalSuccessfulCalls    = self.totalSuccessfulCalls;
    new.totalNumRetries         = self.totalNumRetries;
    new.meanAverageLatency      = self.meanAverageLatency;
    
    return new;
}

@end
