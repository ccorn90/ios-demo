//
//  UIHelpers.h
//  iOS Demo
//
//  Created by Christopher Cornelius on 8/29/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIHelpers : NSObject

// The height of nav+status bar
+(CGFloat) navAndStatusBarHeight;

// Resets a frame to position 0,0
+(CGRect) rebaseRect:(CGRect)rect;

// sets values on a view:
+(void) setX:(float)x onView:(UIView*)view;
+(void) setY:(float)y onView:(UIView*)view;
+(void) setW:(float)w onView:(UIView*)view;
+(void) setH:(float)h onView:(UIView*)view;

// Center a view in its parent:
+(void) centerVertically:(UIView*)view inView:(UIView*)srcview;
+(void) centerHorizontally:(UIView*)view inView:(UIView*)srcview;
+(void) centerView:(UIView*)view inView:(UIView*)srcview;


@end
