//
//  DebugManager.m
//  DebugManager
//
//  Created by Aimago/man
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  24.12.2013   man    Initial release
//  13.03.2014   man    Fixed memory leak by Hardwig


#import "DebugManager.h"

@implementation DebugManager

static DebugManager *sharedInstance = nil;

//! Gets the shared instance and create it if necessary
/** 
 * This function shoould be used to access the singleton object. The function automatically creates
 * the object if it doesn't exist before
*/
+ (DebugManager *)sharedInstance {
    if ( sharedInstance == nil ) {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    
    return sharedInstance;
}

//! Init method which is called internally by the singleton initialization
- (id) init
{
    self = [super init];
    
    if ( self ) {
        self.debuglevel = DebugLevelErrors;
    }
    
    return self;
}

// dealloc method will never be called, as the singleton survives for the singleton survives for the duration of the app
// Implement it anyway
-(void) dealloc
{
    // This will never be callse
    [super dealloc];
}

// We don't want to allocate a new instance, so return the current one
+ (id)allocWithZone:(NSZone*)zone {
    return [[self sharedInstance] retain];
}

// Equally we don't want to generate multipe copies
- (id)copyWithZone:(NSZone *)zone {
    return self;
}

// Do nothing, we don't have a retain counter
- (id) retain {
    return self;
}

// Replace the retain counter so we can never release this object
- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

// This function is empty, we don't want to let the user release this object
- (oneway void) release {
    
}

// Do nothing
- (id) autorelease {
    return self;
}


//! Writes to NSLog depending on debuglevel
/**
 * This function writes to the NSLog if the debuglevel set in the manager is equal or higher than the
 * debug level of the function call
 *
 * @param level Debug level. Integer 0..3
 * @param formatString message including format litterals, plus format arguments
*/
+ (void) writeDebugLogWithLevel:(int) level messsage:(NSString*) formatString, ... NS_FORMAT_FUNCTION(2,0) {
    DebugManager* dm = [DebugManager sharedInstance];
    
    if ( dm.debuglevel >= level )
    {
        va_list args;
        va_start(args, formatString);
        NSString* fs = [[[NSString alloc] initWithFormat:formatString arguments:args] autorelease]; 
        NSLog(@"%@", fs);
        va_end(args);
    }
}

@end

