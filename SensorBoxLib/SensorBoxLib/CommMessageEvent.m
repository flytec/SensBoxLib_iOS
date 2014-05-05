//
//  CommMessageEvent.m
//  SensorBoxLib
//
//  Created by Marc Andre on 6/20/12.
//  Copyright (c) 2012-2013 Aïmago SA. All rights reserved.
//
//  History
//  =======
//  26.4.2012   man    First Release

#import "CommMessageEvent.h"

@implementation CommMessageEvent

@synthesize eventCode;

//! Initialize message with event code
/** 
 *  Initializes the class with event code to be sent
 *  @param inEventCode Event Code. See define list with valid codes
 *  @param inExpectResponse TRUE if response from FlySens is expected. In that case the 
 *         FlySens will send a reply message to ACK/NACK the message
 *  @returns Initialized object
*/     
- (id) initWithEventCode: (uint16_t)inEventCode
     expectResponse:(BOOL)inExpectResponse
{
    self = [super initWithCode:COMMMESSAGE_MSGCODE_EVENT expectResponse:inExpectResponse];
    if ( self )
    {
        self.eventCode = inEventCode;
    }
    
    return self;
}

//! Returns packet data to be sent
/** 
 *  This function is internally used by CommunicationService to pack the message
 *  data. See base class for details.
 *  @param messageData Reference to NSMutableData to be filled with the data to be sent 
*/  
- (void) getMessageData:(NSMutableData *)messageData
{
    uint8_t mc = self.messageCode;
    [messageData appendBytes:&mc length:1];
    [messageData appendBytes:&eventCode length:2];
}

//! Parse received data from FlySens
/**
 *  This function is internally used by CommunicationService to parse the received
 *  message data. See base class for details.
 *  @param messageData Data from FlySens
 *  @return Returns TRUE if the received data is the last packet.   
**/  
- (Boolean) addReceivedData:(NSData*)messageData
{
    if ( [super addReceivedData:messageData] ) 
    {
        
        if ( self.receivedCode == COMMMESSAGE_MSGCODE_ACK )
        { 
            // Parse the response
            char buffer;
            [self.receivedData getBytes:&buffer length:1];
            
            if ( buffer == 0 )            
            {
                self.messageReplyStatus = MessageReplyStatusAck;
            }
            else 
            {
                self.messageReplyStatus = MessageReplyStatusError;
            }
            return TRUE;
        }
    }
    return FALSE;
        
}

@end
