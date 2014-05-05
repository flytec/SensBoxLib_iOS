//
//  CommMessageSettings.m
//  SensorBoxLib
//
//  Created by Marc Andre on 6/15/12.
//  Copyright (c) 2012-2013 Aïmago SA. All rights reserved.
//
//  History
//  =======
//  26.4.2012   man    First Release


#import "CommMessageSettings.h"

@implementation CommMessageSettings

@synthesize sendString;
@synthesize receivedString;

//! Initialize message with string
/**
 *  Initializes the class with the settings string to be sent. 
 *  @param inSendString The settings string is either just the setting name (e.g. "QNH_Pa") to read a setting or
 *  it is a assignment string setting=value (e.g. "QNH_Pa=101325") to write a setting.
 *  @param inExpectResponse TRUE if a response from FlySens is expected. If FALSE no response will be sent. A read 
 *  setting command should have set paramter to true
*/     
- (id) initWithString: (NSString*)inSendString
          expectResponse:(BOOL)inExpectResponse
{
    self = [super initWithCode:COMMMESSAGE_MSGCODE_SETTINGS expectResponse:inExpectResponse];
    if ( self )
    {
        self.sendString = inSendString;
        self.receivedString = @"";
    }
    
    return self;
}

- (void) dealloc
{
    self.sendString = nil;
    self.receivedString = nil;
    [super dealloc];
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
    [messageData appendData:[self.sendString dataUsingEncoding:NSASCIIStringEncoding]];
    mc = 0;
    [messageData appendBytes:&mc length:1];
}

//! Returns packet data to be sent
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
    
        // Parse the response
        if ( self.receivedCode == COMMMESSAGE_MSGCODE_ACK && self.receivedData.length > 0 )
        { 
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
            self.receivedString = @"";
            return TRUE;
        }
        else if ( self.receivedCode == COMMMESSAGE_MSGCODE_SETTINGS ) 
        {
            self.messageReplyStatus = MessageReplyStatusAck;
            self.receivedString = [[[NSString alloc] initWithData:self.receivedData encoding:NSASCIIStringEncoding] autorelease];
            return TRUE;
        }
    } 
    return  FALSE;
}

@end
