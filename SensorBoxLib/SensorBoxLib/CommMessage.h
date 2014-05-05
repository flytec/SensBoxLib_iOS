//
//  CommMessage.h
//  SensorBoxLib
//
//  Created by Aimago/man 
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  26.4.2012   man    First Release

#import <Foundation/Foundation.h>

//! ACK message code from protocol
#define COMMMESSAGE_MSGCODE_ACK 0x00

//! Maximum packet length to be used.
#define MAXPACKETLENGTH 18


//! Generic Message class for CommunicationService
/**
 *  This implementation is the base implementatoin for a message.
 *  It may be derived for specific messages
*/  
@interface CommMessage : NSObject

//! TRUE if a response to the message is expected
@property(nonatomic) BOOL expectResponse;

//! Message code as speicified by the SensorBox
@property(nonatomic) uint8_t messageCode;

//! Received data (as binary)
@property(nonatomic, retain) NSMutableData* receivedData;

//! Received code 
@property(nonatomic) uint8_t receivedCode;

//! SequenceId
/**
 *  The sequenceId will be set by the CommunicationService upon
 *  sending of the message
*/  
@property(nonatomic) int sequenceId;

//! Parsed message Response code 
enum {
	GetDataResponseError = 0,
	GetDataResponseNextPacketToFollow,
  GetDataResponseLastPacket
};
typedef NSInteger GetDataResponseType;

//! Parsed message reply status
enum {
    MessageReplyStatusNone = 0,
    MessageReplyStatusAck,
    MessageReplyStatusError
};
typedef NSInteger MessageReplyStatus;

//! Message reply status 
@property(nonatomic) MessageReplyStatus messageReplyStatus;

- (void) getMessageData: (NSMutableData*)messageData;
- (id) initWithCode: (uint8_t)messageCode
     expectResponse:(BOOL)inExpectResponse;
- (Boolean) addReceivedData:(NSData*)messageData;


@end
