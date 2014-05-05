//
//  DebugManager.h
//  DebugManager
//
//  Created by Aimago/man
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  24.12.2013   man    Initial release


#import <Foundation/Foundation.h>

//! Debug levels
enum {
    //! No output
    DebugLevelNone = 0,
    //! Only errors
    DebugLevelErrors = 1,
    //! Information messages and errors
    DebugLevelInfo = 2,
    //! Verbose output
    DebugLevelVerbose = 3
};


@interface DebugManager : NSObject
{
    
}

+ (id)sharedInstance;

//! Debuglevel 0..3 with 3 being most verbose
@property(nonatomic) int debuglevel;

+ (void) writeDebugLogWithLevel:(int) level messsage:(NSString*) formatString, ... NS_FORMAT_FUNCTION(2,0);


@end
