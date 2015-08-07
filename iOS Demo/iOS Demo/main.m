//
//  main.m
//  iOS Demo
//
//  Created by Christopher Cornelius on 8/6/15.
//
//

#import <UIKit/UIKit.h>
#import "Singletons.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([Singletons class]));
    }
}
