//
//  Logging.h
//  iOS Demo
//
//  (c) 2013, updated 2015
//  Available under GNU Public License v2.0
//  Credit to several internet sources that paved the way to writing this.  The most useful was:
//  http://doing-it-wrong.mikeweller.com/2012/07/youre-doing-it-wrong-1-nslogdebug-ios.html
//
//  Credit also to my first boss, who would not allow a single NSLog to go into prod.  If we
//  couldn't debug production failures without the system log, it wasn't ready to go out to
//  competitors who might reverse-engineer it.  Thanks, K.
//


#ifndef cjc_Logging_h
#define cjc_Logging_h

// Logging.h and Logging.m define a flexible logging
// system.  The different log levels are as follows:
// Debug : LogD(tag, format, args) - prints out in DEBUG build only
// Info  : LogI(format, args)      - alias of LogD which prints regardless of tag
// Warn  : LogW(tag, format, args) - prints in DEBUG and RELEASE_INTERNAL
// Error : LogE(tag, format, args) - prints in DEBUG and RELEASE_INTERNAL
// Worst : LogWTF(tag, format, args) - prints out no matter what the tag is, no matter when


// List the log tags you want to log here.  Make sure you have a trailing comma!
// If you want to log for ALL tags, leave this blank
#define ACTIVE_LOG_TAGS //@"none",
//@"network",



/********** LOGGING INTERNAL STUFF **********/

// This macro creates a declaration for each function if it's wanted:
#define __MAKE_LOG_FUNC_DECL(LEVEL,NAME) \
FOUNDATION_EXPORT void NAME (NSString* tag, NSString* format, ...);


// Do different things for DEBUG, RELEASE_INTERNAL, RELEASE:
#ifdef DEBUG
__MAKE_LOG_FUNC_DECL(ASL_LEVEL_DEBUG, LogD)
__MAKE_LOG_FUNC_DECL(ASL_LEVEL_WARNING, LogW)
__MAKE_LOG_FUNC_DECL(ASL_LEVEL_ERR, LogE)
#else
#ifdef RELEASE_INTERNAL
#define LogD(tag, format, ...)
__MAKE_LOG_FUNC_DECL(ASL_LEVEL_WARNING, LogW)
__MAKE_LOG_FUNC_DECL(ASL_LEVEL_ERR, LogE)
#else
#define LogD(tag, format, ...)
#define LogW(tag, format, ...)
#define LogE(tag, format, ...)
#endif
#endif

// LogWTF is constantly available and LogI is a separate #def:
FOUNDATION_EXPORT void LogWTF(NSString* format, ...);
#define LogI(format, ...) LogD(@"INFO", format, ##__VA_ARGS__)

#undef __MAKE_LOG_FUN_DEC

#endif // cjc_Logging_h
