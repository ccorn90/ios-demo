//
//  NetworkManagerStatistics.h
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

/** This serves as a "snapshot" of the status of a network manager. */

#import <Foundation/Foundation.h>

@interface NetworkManagerStatistics : NSObject <NSCopying>

// Logs all to WARN - DO NOT USE THIS IN PROD!!
-(void) printAll;

// These are about the calls currently in flight - how many
// are happening, how many times they've been retried, etc.
@property (nonatomic) NSDate* date;
@property (nonatomic) UInt64  numCallsInFlight;
@property (nonatomic) UInt64  numRetriesInFlight;

// These are a global record – the mean average latency,
// the number of failed calls of each type, etc.
@property (nonatomic) UInt64 failuresNoConnection;
@property (nonatomic) UInt64 failuresTimedOut;
@property (nonatomic) UInt64 failuresBadRequest;
@property (nonatomic) UInt64 failuresBadServer;
@property (nonatomic) UInt64 failuresInternalError;

@property (nonatomic) UInt64 totalFailedCalls;
@property (nonatomic) UInt64 totalSuccessfulCalls;
@property (nonatomic) UInt64 totalNumRetries;
@property (nonatomic) double meanAverageLatency;  // for successful calls

@end
