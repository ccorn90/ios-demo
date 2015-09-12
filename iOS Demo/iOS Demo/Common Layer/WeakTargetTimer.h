//
//  WeakTargetNSTimer.h
//  iOS Demo
//
//  Created by Christopher Cornelius on 9/9/15.
//

// This solves a classic problem - NSTimers retain their target.  So this timer sets target to self
// (if you call the right initializer!) and holds a weak reference to the target it is going to call out to.
// Now you can finally have an ivar timer that points to self without creating a retain cycle!

#import <Foundation/Foundation.h>

@interface WeakTargetTimer : NSObject

+(WeakTargetTimer*) timerWithTimerInterval:(NSTimeInterval)timeInterval
                                    target:(__weak id)target
                                  selector:(SEL)selector
                                   repeats:(BOOL)repeats;

-(void) invalidate;
-(void) fire;
-(BOOL) valid;

-(void) scheduleInRunLoop:(NSRunLoop*)runLoop forMode:(NSString *)mode;

@end
