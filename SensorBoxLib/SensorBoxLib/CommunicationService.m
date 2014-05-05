//
//  CommunicationService.m
//  SensorBoxLib
//
//  Created by Aimago/man 
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  26.04.2012   man    First Release
//  06.06.2012   man    Finalize & Documentation
//  07.11.2013   man    Added retry timeout and file transfer functionality
//  24.12.2013   man    Improvements on delegate handling
//  13.03.2014   man    Implemented suggested changes by Hardwig


#import "CommunicationService.h"
#import "CommMessage.h"
#import "CommMessageFile.h"
#import "UUIDHelper.h"

@implementation CommunicationService

@synthesize lastSequenceId;
@synthesize commMessage;
@synthesize timeout;
@synthesize fileHelperDelegate;


//*************************************************************
//* 
//* Private functions first
//*
//*************************************************************

//! Increments the sequence Id
/** 
 *  This function incremetns the sequence Id and wraps when
 *  necessary
 *  
 *  @returns updated sequence Id
*/    
- (int) incrementSequenceId
{
    lastSequenceId++;
    if ( lastSequenceId > 0x3f ) lastSequenceId = 0;
    return lastSequenceId;
}

//! Will be called on dispose of the object
- (void) dealloc
{
    self.commMessage = nil;
    self.timeout = nil;
    self.fileHelperDelegate = nil;
    self.timeout = nil;
    
    [super dealloc];
}


//*************************************************************
//* 
//* Public functions
//*
//*************************************************************


//! Discover Characteristics when connected
/**
 *  This function is called by the SensorBox class when it is connecting to the 
 *  SensorBox.
 *  This overrites the standard implementation and request characteristics 
 *  discovery 
 *  
 *  @returns TRUE   
*/ 
- (BOOL) firstDiscover
{
    [self discover];
    return TRUE;
}

//! Reports completion of discovery for characteristics
/**
 *  This function is called by SensorBox upon received callback from CBCentralManager
 *  on completion of characteristics discovery
 *  We add attaching to the file transfer notify
 */
- (void) setFinishDiscover
{
    [super setFinishDiscover];

}


//! Sends a message to the SensorBox
/**
 *  This function sends a CommMessage to the SensorBox. All information 
 *  is stored in the CommMessage object. The object also determines if a response
 *  is requested. 
 *  The message is automatically split into several packets if its length exceeds
 *  the maximum packet size.    
 *  Please refer to the CommMessage object for more details
 *  
 *  @param message CommMessage to be sent
*/      
- (void) sendMessage:(CommMessage*)message
{
    //TODO: Handle case when waiting for response
    
    // Prepare message for sending.
    NSMutableData* msg = [[[NSMutableData alloc] initWithCapacity:MAXPACKETLENGTH] autorelease];
    uint8_t temp[MAXPACKETLENGTH];
    
    message.sequenceId = [self incrementSequenceId];
    NSMutableData* payload = [[[NSMutableData alloc] initWithCapacity:0] autorelease];
    [message getMessageData:payload];
    
    int len = payload.length;
    int i = 0;
    while ( len > 0 ) 
    {
        // Split the message into several packets 
        NSRange destRange, sourceRange;
        uint8_t header = (message.sequenceId << 2 );
        if ( message.expectResponse ) 
        {
            self.commMessage = message;
            header |=  0x02;
        }
        if ( len > MAXPACKETLENGTH-1 ) 
        {
            // More packets will follow;
            destRange = NSMakeRange(1, MAXPACKETLENGTH-1);
            sourceRange = NSMakeRange(i, MAXPACKETLENGTH-1);
            len -= MAXPACKETLENGTH-1;
            [ msg setLength:MAXPACKETLENGTH ];
            i += MAXPACKETLENGTH-1;
        }
        else {
            // Last packet
            destRange = NSMakeRange(1, len);
            sourceRange = NSMakeRange(i, len);
            [ msg setLength:len+1 ];
            len = 0;
            header |= 0x01;
        }
        
        // Send the message
        [payload getBytes:&temp range:sourceRange];
        [msg replaceBytesInRange:destRange withBytes:temp];
        destRange = NSMakeRange(0, 1);
        [msg replaceBytesInRange:destRange withBytes:&header];
        
        
        [self writeWithUUIDString:UUID_TRANSFER data:msg];
    }
    if ( message.expectResponse )
    {
        self.commMessage = message;
        self.timeout = [[[NSDate alloc] initWithTimeIntervalSinceNow:COMM_RETRY_TIMEOUT] autorelease];
        [self readWithUUIDString:UUID_TRANSFER];
    }
}


//! Catches value update after read request and handles for communction
/**
 *  This function is overwritten from the default Service implementation because
 *  in CommunicationService we need to handle the data ourselfs.
 *  
 *  @param characteristic Characteristic with updated value.
 **/     
- (void) setValueUpdated:(CBCharacteristic *)characteristic
{
    NSString* uuid = [UUIDHelper CBUUIDToString:characteristic.UUID];
    if ( [ uuid isEqualToString:UUID_TRANSFER ] ) 
    {
        if ( self.commMessage )
        {
            self.timeout = nil;
            
            if ( characteristic.value.length >= 1 )
            {
                unsigned char header;
                [characteristic.value getBytes:&header length:1];
                int seqId = (header >> 2);
                if ( seqId != commMessage.sequenceId ) 
                {
                    // This is a problem! But we can't do anything else than ignoring it...
                    return;
                }
                
                if ( [self.commMessage addReceivedData:characteristic.value] )
                {
                    CommMessage* msg = [[self.commMessage retain] autorelease];
                    // This is the last message!
                    self.commMessage = nil;
                    
                    if ( self.delegate != nil ) [(id)self.delegate messageReceived:self message:msg];
                    
                    if ( self.fileHelperDelegate != nil && [ msg isKindOfClass:[CommMessageFile class]] )
                    {
                        [self.fileHelperDelegate messageReceived:self message:msg];
                    }
                    msg = nil;
                }
                else
                {
                    // request next packet
                    self.timeout = [[[NSDate alloc] initWithTimeIntervalSinceNow:COMM_RETRY_TIMEOUT] autorelease];
                    [self readWithUUIDString:UUID_TRANSFER];
                }            
            }
        }
    }
    else if ( [ uuid isEqualToString:UUID_FILETRANSFER ] )
    {
        // Message was for file transfer. Forward it to the FileTransferHelper
        if ( self.fileHelperDelegate != nil )
        {
            [self.fileHelperDelegate fileChunkReceived:self data:characteristic.value];
        }
        
    }
    else
    {
        // unknown message. Just forward it to our delegate
        if ([[self delegate] respondsToSelector:@selector(sensorBox:valueUpdated:characteristicUUID:)])
					[[self delegate] sensorBox:[self sensorBox] valueUpdated:self characteristicUUID:uuid];
    }
}

//! Catches value update error after read request and handles for communction
/**
 *  This function is overwritten from the default Service implementation because
 *  in CommunicationService we need to handle the data ourselfs.
 *  In caes of value update error we retry. 
 *  
 *  @param error Error object 
 *  @param characteristic Characteristic with updated value.
 **/     
- (BOOL) setValueUpdateError:(NSError*)error forCharacteristic:(CBCharacteristic*)characteristic
{
 
    NSString* uuid = [UUIDHelper CBUUIDToString:characteristic.UUID];
    if ( [ uuid isEqualToString:UUID_TRANSFER ] ) 
    {
        if ( self.commMessage )
        {
            if ( self.timeout != nil && [self.timeout compare:[NSDate date]] == NSOrderedAscending )
            {
                if ( self.delegate != nil ) [(id)self.delegate timeoutWaitingResponse:self message:self.commMessage];
            }
            else
            {
                // Request again
                [self readWithUUIDString:UUID_TRANSFER];
            }
            return true;
        }
    }
    return false;
}


//! Enables/Disables notify for file transfer characteristic
/**
 *  This function is used by the FileTransferHelper to enable/disable the notify on the
 *  file transfer helper
 *
 *  @param enabled True if notify shall be enabled
 **/
- (void) setFileNotify:(BOOL)enabled
{
    [self setNotifyWithUUIDString:UUID_FILETRANSFER enableNotify:enabled ];
}


@end
