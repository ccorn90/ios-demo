//
//  Logging.m
//  iOS Demo
//
//  (c) 2013, updated 2015
//  Available under GNU Public License v2.0
//

#include <asl.h>

#import <Foundation/Foundation.h>
#import "Logging.h"


// This returns a list of all the log tags we want to listen to:
#ifdef DEBUG
static NSArray* __getAllLogTags() {
    static NSArray* __allLogTagsArray;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __allLogTagsArray = [NSArray arrayWithObjects:ACTIVE_LOG_TAGS nil];
    });
    return __allLogTagsArray;
}
#endif


// This function adds the standard error log as an output for AppleSystemLogging from this app.
// Basically, this makes the messages we generate here go to the console, too.  The way to
// specify what message gets printed is kind of clever - it's the same as syslog so I made a custom
// message that I like.  I also changed to ISO8601 time.
static void __addStderrOnce()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        asl_add_output_file(NULL, STDERR_FILENO, "$Time [$(PID)] <$((Level)(str))>: $Message", "ISO8601", ASL_FILTER_MASK_UPTO(ASL_LEVEL_DEBUG), ASL_ENCODE_SAFE);
    });
}

// This macro defines a logging function that takes tags and uses them:
#define __MAKE_LOG_FUNC_IMPL(LEVEL,NAME) \
void NAME (NSString* tag, NSString* format, ...) { \
    NSArray* allTags = __getAllLogTags(); \
    if([allTags count] == 0 || [allTags containsObject:tag] || [tag isEqualToString:@"INFO"]) { \
        __addStderrOnce(); \
        va_list args;  va_start(args, format); \
        NSString* message = [[NSString alloc] initWithFormat:format arguments:args]; \
        asl_log(NULL, NULL, (LEVEL), "%s - %s", [tag UTF8String], [message UTF8String]); \
        va_end(args);\
    } \
}

// This macro defines a logging function that takes tags and ignores them:
#define __MAKE_LOG_FUNC_IMPL_NOTAGGING(LEVEL,NAME) \
void NAME (NSString* tag, NSString* format, ...) { \
{ \
__addStderrOnce(); \
va_list args;  va_start(args, format); \
NSString* message = [[NSString alloc] initWithFormat:format arguments:args]; \
asl_log(NULL, NULL, (LEVEL), "%s - %s", [tag UTF8String], [message UTF8String]); \
va_end(args);\
} \
}

// And now we use the above macro to define all the logging functions:
#ifdef DEBUG
__MAKE_LOG_FUNC_IMPL(ASL_LEVEL_DEBUG, LogD)
__MAKE_LOG_FUNC_IMPL_NOTAGGING(ASL_LEVEL_WARNING, LogW)
__MAKE_LOG_FUNC_IMPL_NOTAGGING(ASL_LEVEL_ERR, LogE)
#else
#ifdef RELEASE_INTERNAL
__MAKE_LOG_FUNC_IMPL_NOTAGGING(ASL_LEVEL_WARNING, LogW)
__MAKE_LOG_FUNC_IMPL_NOTAGGING(ASL_LEVEL_ERR, LogE)
#endif
#endif


// define LogWTF:
void LogWTF(NSString* format, ...) {
    __addStderrOnce();
    va_list args;  va_start(args, format);
    NSString* message = [[NSString alloc] initWithFormat:format arguments:args];
    asl_log(NULL, NULL, ASL_LEVEL_CRIT, "%s", [message UTF8String]);
    va_end(args);
}



#undef __MAKE_LOG_FUNC_IMPL