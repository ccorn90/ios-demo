//
//  NetworkManagerStatistics.h
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

/** This serves as a "snapshot" of the status of a network manager. */

#import <Foundation/Foundation.h>

@interface NetworkManagerStatistics : NSObject

// These are about the calls currently in flight - how many are happening, 
@property (nonatomic) long numCallsInFlight;
@property (nonatomic) long numRetriesInFlight;

@end
