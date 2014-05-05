//
//  CommMessageSettings.h
//  SensorBoxLib
//
//  Created by Marc Andre on 6/15/12.
//  Copyright (c) 2012-2013 Aïmago SA. All rights reserved.
//
//  History
//  =======
//  26.4.2012   man    First Release

#import "CommMessage.h"

//! Settings Message code
#define COMMMESSAGE_MSGCODE_SETTINGS 0x02

//! Settings message (for CommunicationService)
/**
 *  This class represents a communication message to be sent to FlySens when accessing
 *  the settings of the system. 
 *  The message can be used to read or write any settings of the FlySens device.  
 *  Please refer to the protocol description for the full details.
*/ 
@interface CommMessageSettings : CommMessage

//! String to be sent. 
/**
 *  The settings string is either just the setting name (e.g. "QNH_Pa") to read a setting or
 *  it is a assignment string setting=value (e.g. "QNH_Pa=101325") to write a setting.
*/  
@property (retain,nonatomic) NSString* sendString;
//! String received from FlySens
/**
 *  When reading a setting this string will be filled with the response from FlySens. The 
 *  response is formatted as Setting=Value, e.g. "QNH_Pa=101325"
*/  
@property (retain,nonatomic) NSString* receivedString;

- (id) initWithString: (NSString*)inSendString
       expectResponse:(BOOL)inExpectResponse;

@end
