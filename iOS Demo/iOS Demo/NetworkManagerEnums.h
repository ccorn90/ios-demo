//
//  NetworkManagerEnums.h
//  iOS Demo
//
//  (c) 2015
//  Available under GNU Public License v2.0
//

/** Enums used by NetworkManagerInterface and its implementors. */

// Error types for NetworkManager
typedef enum {
    // Null case:
    NetworkManagerErrorNoError = 0,
    
    // These indicate that a retry might success:
    NetworkManagerErrorNoConnection,
    NetworkManagerErrorTimedOut,
    
    // With these errors, a retry is unlikely to succeed:
    NetworkManagerErrorBadRequest,  // i.e. 400-type error
    NetworkManagerErrorBadServer,   // i.e. 500-type error, range error, etc
    
    // A logic error – this is a critical failure of the network manager.
    NetworkManagerErrorInternal,
} NetworkManagerError;