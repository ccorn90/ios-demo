//
//  UIHelpers.m
//  iOS Demo
//
//  Created by Christopher Cornelius on 8/29/15.
//
//

#import "UIHelpers.h"

@implementation UIHelpers

// The height of nav+status bar
+(CGFloat) navAndStatusBarHeight {
    // TASK: dynamically determine this!!!
    return 64.0f;
}

// Resets a frame to position 0,0
+(CGRect) rebaseRect:(CGRect)rect {
    return CGRectMake(0.0f, 0.0f, rect.size.width, rect.size.height);
}

// sets values on a view:
+(void) setX:(float)x onView:(UIView*)view {
    view.frame = CGRectMake(x, view.frame.origin.y, view.frame.size.width, view.frame.size.height);
}
+(void) setY:(float)y onView:(UIView*)view {
    view.frame = CGRectMake(view.frame.origin.x, y, view.frame.size.width, view.frame.size.height);
}
+(void) setW:(float)w onView:(UIView*)view {
    view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, w, view.frame.size.height);
}
+(void) setH:(float)h onView:(UIView*)view {
    view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, h);
}

+(void) centerVertically:(UIView*)view inView:(UIView*)srcview {
    if(view != nil && srcview != nil) {
        CGFloat val = srcview.frame.size.height - view.frame.size.height;
        val /= 2.0f;
        [UIHelpers setY:val onView:view];
    }
}

+(void) centerHorizontally:(UIView*)view inView:(UIView*)srcview {
    if(view != nil && srcview != nil) {
        CGFloat val = srcview.frame.size.width - view.frame.size.width;
        val /= 2.0f;
        [UIHelpers setX:val onView:view];
    }
}

+(void) centerView:(UIView*)view inView:(UIView*)srcview {
    [UIHelpers centerHorizontally:view inView:srcview];
    [UIHelpers centerVertically:view   inView:srcview];
}

@end
