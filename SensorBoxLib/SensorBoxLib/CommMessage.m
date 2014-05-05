//
//  CommMessage.m
//  SensorBoxLib
//
//  Created by Aimago/man 
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  26.4.2012   man    First Release

#import "CommMessage.h"

@implementation CommMessage

@synthesize expectResponse;
@synthesize messageCode;
@synthesize sequenceId;
@synthesize receivedData;
@synthesize messageReplyStatus;
@synthesize receivedCode;

//*************************************************************
//* 
//* Public functions
//*
//*************************************************************

//! Initialize message
/** 
 *  Initializes the message to be sent
 *  
 *  @param inMessageCode Message code to be sent. See SensorBox documentation for details
 *  @param inExpectResponse TRUE if a response is expected/requested
 *  @returns Initialized object
*/     
- (id) initWithCode: (uint8_t)inMessageCode
               expectResponse:(BOOL)inExpectResponse
{
    self = [super init];
    if ( self )
    {
        receivedData = [[ NSMutableData alloc ] init];
        self.expectResponse = inExpectResponse;
        self.messageCode = inMessageCode;
        self.messageReplyStatus = MessageReplyStatusNone;
    }
    
    return self;
}

- (void) dealloc
{
    self.receivedData = nil;
    [super dealloc];
}

//! Returns the message data
/**
 *  This function adds the message data to the NSMutableData object.
 *  The function adds the data such as it should be sent, but without
 *  taking care of the message splitting. This will be done by the
 *  CommunicationService upon sending.
 *  This function is called from the CommunicationService to get the
 *  data to be sent
 *  
 *  @param messageData Reference to NSMutableData to be filled with the data to be sent
*/        
- (void) getMessageData:(NSMutableData *)messageData
{
    [messageData appendBytes:&messageCode length:1];
}

//! Add data from FlySens to Message
/**
 *  This function gets called by the CommunicationService to 
 *  add received data to the receive buffer. The derived classes will overide this function
 *  and parse the received data.
 *  @param messageData Data from FlySens
 *  @return Returns TRUE if the received data is the last packet.   
**/  
- (Boolean) addReceivedData:(NSData*)messageData
{
    if ( messageData.length == 0 ) return FALSE;
    char mydata[messageData.length];
    [messageData getBytes:mydata length:messageData.length];
    NSInteger start = 1;
    if ( self.receivedData.length == 0 )
    {
        if ( messageData.length > 1 ) self.receivedCode = mydata[1];
        start = 2;
    }
    [self.receivedData appendBytes:mydata+start length:messageData.length-start];
    
    return ( mydata[0] & 0x01 ); // Is this the last message?
}

@end
