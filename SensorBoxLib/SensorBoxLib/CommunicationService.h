//
//  CommunicationService.h
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

#import "Service.h"
#import "CommMessage.h"

#define COMM_RETRY_TIMEOUT 3

@protocol CommunicationServiceDelegate ;
@protocol CommunicationServiceFileHelperDelegate;

//! Service class for Communication service
/** 
 *  Communication service is used for complex bidirectional communication between 
 *  the master and the senorbox. 
 *  It can be used to read/write settings or initiate events.   
*/  
@interface CommunicationService : Service

//! Last sequence Id. Internally used.
@property(nonatomic) int lastSequenceId;

//! Last message. Used for waiting replays
@property(nonatomic, retain) CommMessage* commMessage;

//! Timeout for waiting for reply from device for read request
@property(nonatomic, retain) NSDate* timeout;

//! Special delegate that will be used by the FileTransferHelper component
@property(nonatomic, assign) id<CommunicationServiceFileHelperDelegate> fileHelperDelegate;

//! UUID for Communication service
#define UUID_COMMSERVICE @"<aba27100 143b4b81 a444edcd 0000f010>"

//! UUID for data transfer characteristic
#define UUID_TRANSFER @"<aba27100 143b4b81 a444edcd 0000f012>"

//! UUID for file transfer
#define UUID_FILETRANSFER @"<aba27100 143b4b81 a444edcd 0000f013>"


- (void) sendMessage:(CommMessage*)message;

- (void) setFileNotify:(BOOL)enabled;

@end


//! Delegate for communication service update callbacks
/**
 *  This delegate protocol is used to report changes from a CommunicationService in a SensorBox
 */ 
@protocol CommunicationServiceDelegate <ServiceDelegate>
@optional

//! Reports an received message
/**
 *  This function is invoked upon completion of a message read.
 *  
 *  @param service Service object which was updated
 *  @param message Message that is updated containing type and value
 **/    
-(void) messageReceived:(CommunicationService*)service message:(CommMessage*) message;

//! Timeout occured while waiting for requested response
/**
 * This function is invoked when a timeout occured while waiting for a reply.
 * 
 * @param service Service invoking the function
 * @param message Message for which the reply was expected.
 **/    
-(void) timeoutWaitingResponse:(CommunicationService*) service message:(CommMessage*)message;

@required

@end

//! Delegate to sens messages to FileTransferHelper
/**
 * This delegate is specifically implemented to submit data to the FileTransFer helper
 */ 
@protocol CommunicationServiceFileHelperDelegate
@optional

//! Reports an received message
/**
 *  This function is invoked upon completion of a message read.
 *  
 *  @param service Communication service invoking
 *  @param message Message that is updated containing type and value
 **/    
- (void) messageReceived:(CommunicationService*)service message:(CommMessage*) message;

//! Reports received file data
/**
 *  This function is invoked upon receiving of file data chunk. 
 *  
 *  @param service Communicatoin service invoking
 *  @param data Data received
 **/    
-(void) fileChunkReceived:(CommunicationService*)service data:(NSData*) data;

@required

@end
