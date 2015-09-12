//
//  WeakTargetNSTimer.m
//  iOS Demo
//
//  Created by Christopher Cornelius on 9/9/15.
//
//

#import "WeakTargetTimer.h"

@interface WeakTargetTimer ()

@property (nonatomic, retain) NSTimer* internalTimer;
@property (nonatomic, weak)   id target;
@property (nonatomic) SEL selector;

@end

@implementation WeakTargetTimer

+(WeakTargetTimer*) timerWithTimerInterval:(NSTimeInterval)timeInterval
                                    target:(__weak id)target
                                  selector:(SEL)selector
                                   repeats:(BOOL)repeats
{
    WeakTargetTimer* timer;
    if(target != nil && selector != NULL) {
        timer = [[WeakTargetTimer alloc] init];
        timer.internalTimer = [NSTimer timerWithTimeInterval:timeInterval target:timer selector:@selector(timerFired) userInfo:nil repeats:repeats];
        timer.target = target;
        timer.selector = selector;
    }
    
    return timer;
}

-(void) timerFired {
    // Bind the target strongly while we do this:
    __strong id t = self.target;
    
    if(t != nil) {
        // I know, I know - there's a warning here.
        // TODO: prove correct and suppress this warning.
        [t performSelector:self.selector];
    }
}


-(void) invalidate {
    [self.internalTimer invalidate];
}
-(void) fire {
    [self.internalTimer fire];
}
-(BOOL) valid {
    return self.internalTimer.valid;
}

-(void) scheduleInRunLoop:(NSRunLoop*)runLoop forMode:(NSString *)mode {
    if(runLoop != nil) {
        [runLoop addTimer:self.internalTimer forMode:mode ?: NSDefaultRunLoopMode];
    }
}

@end
