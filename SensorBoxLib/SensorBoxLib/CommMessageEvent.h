//
//  CommMessageEvent.h
//  SensorBoxLib
//
//  Created by Marc Andre on 6/20/12.
//  Copyright (c) 2012-2013 Aïmago SA. All rights reserved.
//
//  History
//  =======
//  26.04.2012   man    First Release
//  07.11.2013   man    Added event for file transfer

#import "CommMessage.h"

//! PilotEvent Event Code
#define COMMMESSAGE_EVENT_PEV 0x0001
//! Start logging Event Code
#define COMMMESSAGE_EVENT_STARTLOG 0x0002
//! Stop logging Event Code
#define COMMMESSAGE_EVENT_STOPLOG 0x0003
//! Device shutdown Event Code
#define COMMMESSAGE_EVENT_SHUTDOWN 0x0004
//! Dump flight Event Code
#define COMMMESSAGE_EVENT_DUMPFLIGHTS 0x0005
//! BLE Disconnect Event Code
#define COMMMESSAGE_EVENT_DISCONNECT 0x0006
//! Shutdown into file transfer mode Event Code
#define COMMMESSAGE_EVENT_FILETRANSFER 0x0007

//! Event Message code
#define COMMMESSAGE_MSGCODE_EVENT 0x01

//! Event message (for CommunicationService)
/**
 *  This class represents a communication message to be sent to FlySens when a event
 *  shall be called are when the message is replied.
 *  With this event interface commands can be sent to FlySens such as Shutdown, Disconnect
 *  or Start/Stop logging.
 *  Please refer to the protocol description for the full details.
*/         
@interface CommMessageEvent : CommMessage

//! Event code as specified by the SensorBox
@property(nonatomic) uint16_t eventCode;

- (id) initWithEventCode: (uint16_t)inEventCode expectResponse:(BOOL)inExpectResponse;



@end
