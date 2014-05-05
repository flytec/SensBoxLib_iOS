//
//  CommMessageFile.m
//  SensorBoxLib
//
//  Created by Aimago/man 
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  07.11.2013   man    First Release

#import "CommMessageFile.h"

@implementation CommMessageFile

@synthesize sendString;
@synthesize fileOpCode;
@synthesize fileInfoEntry;
@synthesize fileMode;
@synthesize fileHandle;
@synthesize errorCode;

//! Initialize message for find first file operation
/**
 *  Initializes the class with message to request first file in directory.
 *  @param folder name. Use forward slash (/) to separate directory levels
 */
- (id) initFindFileFirst: (NSString*)folder
{
    self = [super initWithCode:COMMMESSAGE_MSGCODE_FILE expectResponse:true];
    if ( self )
    {
        self.sendString = folder;
        self.fileOpCode = COMMMESSAGE_FILEOPCODE_FINDFIRST;
    }
    
    return self;
}

//! Initialize message for find next file operation
/**
 * Initialize the class with message to request next file in directory.
 * Find first file must have previously been sent
 */
- (id) initFindFileNext
{
    self = [super initWithCode:COMMMESSAGE_MSGCODE_FILE expectResponse:true];
    if ( self )
    {
        self.fileOpCode = COMMMESSAGE_FILEOPCODE_FINDNEXT;
    }
    
    return self;
}

//! Initialize the message for open file operation
/**
 * Initialize the class with message to open file
 * @param inFilename must be full path incuding folder. Use forward slash (/) to separate directory levels
 * @param inMode File open mode as specified in SensBox documentation.
 */
- (id) initOpenFile: (NSString*)inFilename mode:(NSInteger) inMode
{
    self = [super initWithCode:COMMMESSAGE_MSGCODE_FILE expectResponse:true];
    if ( self )
    {
        self.sendString = inFilename;
        self.fileMode = inMode;
        self.fileOpCode = COMMMESSAGE_FILEOPCODE_FILEOPEN;
    }
    
    return self;
}

//! Initialize the message for close file operation
/**
 * Initialize the class with message to close file
 * @param handle File handle for file to close. Note currently only one file can be opened at the time.
 */
- (id) initCloseFile:(uint32_t)handle
{
    self= [super initWithCode:COMMMESSAGE_MSGCODE_FILE expectResponse:true];
    if ( self )
    {
        self.fileHandle = handle;
        self.fileOpCode = COMMMESSAGE_FILEOPCODE_FILECLOSE;
    }
    
    return self;
}

//! Initialize the message for read file operation
/** 
 * Initialize the class with message to read file content. The full file will be requested.
 * The file must previously have been opened.
 * @param handle File handle for file to read.
 */
- (id) initReadFile:(uint32_t)handle
{
    self= [super initWithCode:COMMMESSAGE_MSGCODE_FILE expectResponse:true];
    if ( self )
    {
        self.fileHandle = handle;
        self.fileOpCode = COMMMESSAGE_FILEOPCODE_FILEREAD;
    }
    
    return self;
}

//! Initialize the message for abort file operation
/**
 * Initialize the class with message to abort file transfer. This will immediately cancel all file transfer.
 */
- (id) initAbort
{
    self= [super initWithCode:COMMMESSAGE_MSGCODE_FILE expectResponse:true];
    if ( self )
    {
        self.fileOpCode = COMMMESSAGE_FILEOPCODE_ABORT;
    }
    
    return self;
}


- (void) dealloc
{
    self.sendString = nil;
    self.fileInfoEntry = nil;
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
    uint8_t fileop = self.fileOpCode;
    [messageData appendBytes:&mc length:1];
    [messageData appendBytes:&fileop length:1];
    if ( fileop == COMMMESSAGE_FILEOPCODE_FINDFIRST )
    {
        [messageData appendData:[self.sendString dataUsingEncoding:NSASCIIStringEncoding]];
        mc = 0;
        [messageData appendBytes:&mc length:1];
    }
    if ( fileop == COMMMESSAGE_FILEOPCODE_FILEOPEN )
    {
        uint16_t mode = self.fileMode;
        [messageData appendBytes:&mode length:2];
        [messageData appendData:[self.sendString dataUsingEncoding:NSASCIIStringEncoding]];
        mc = 0;
        [messageData appendBytes:&mc length:1];
    }
    if ( fileop == COMMMESSAGE_FILEOPCODE_FILECLOSE )
    {
        uint32_t handle = self.fileHandle;
        [messageData appendBytes:&handle length:4];
    }
    if ( fileop == COMMMESSAGE_FILEOPCODE_FILEREAD )
    {
        uint32_t handle = self.fileHandle;
        [messageData appendBytes:&handle length:4];
        uint32_t size = 0x7fffffff;
        [messageData appendBytes:&size length:4];
    }
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
        self.errorCode = 0;
        
        // Parse the response
        if ( self.receivedCode == COMMMESSAGE_MSGCODE_ACK && self.receivedData.length > 0 )
        {
            // Failure source code or empty packet.
            char buffer;
            [self.receivedData getBytes:&buffer length:1];
            
            self.errorCode = buffer;
            
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
        else if ( self.receivedCode == COMMMESSAGE_MSGCODE_FILE )
        {
            self.messageReplyStatus = MessageReplyStatusAck;
            
            // Reply to file listing operation
            if ( self.fileOpCode == COMMMESSAGE_FILEOPCODE_FINDFIRST || self.fileOpCode == COMMMESSAGE_FILEOPCODE_FINDNEXT)
            {                
                if ( self.receivedData.length < sizeof(comm_filelist_t) + 1 )
                {
                    self.messageReplyStatus = MessageReplyStatusError;
                }
                else
                {
                    comm_filelist_t fileinfo;
                    [self.receivedData getBytes:&fileinfo range:NSMakeRange(1,sizeof(comm_filelist_t))];
                    NSRange range = NSMakeRange(COMMMESSAGE_FILELIST_TYPE_SIZE+1, self.receivedData.length - COMMMESSAGE_FILELIST_TYPE_SIZE - 1);
                    NSData* data = [self.receivedData subdataWithRange:range];
                    
                    unsigned char test[50];
                    [data getBytes:&test length:data.length];

                    
                    NSString* filename = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
                    
                    self.fileInfoEntry = [[[FileInfoEntry alloc] initWithFilename:filename size:fileinfo.size datetime:fileinfo.time fileType:fileinfo.filetype] autorelease];
                }
            }
            
            // Reply to file open operation
            if ( self.fileOpCode == COMMMESSAGE_FILEOPCODE_FILEOPEN )
            {
                if ( self.receivedData.length < 4 )
                {
                    self.messageReplyStatus = MessageReplyStatusError;
                }
                else
                {
                    uint32_t handle;
                    [self.receivedData getBytes:&handle range:NSMakeRange(1,4)];
                    self.fileHandle = handle;
                }
            }
            
            // Reply to file close operation
            if ( self.fileOpCode == COMMMESSAGE_FILEOPCODE_FILECLOSE )
            {
                if ( self.receivedData.length < 3 )
                {
                    self.messageReplyStatus = MessageReplyStatusError;
                }
                else
                {
                    uint8_t resultCode;
                    uint16_t crc;
                    [self.receivedData getBytes:&resultCode  range:NSMakeRange(1,1)];
                    [self.receivedData getBytes:&crc range:NSMakeRange(2,2)];
                    self.fileCrc = crc;
                }
            }
            
            // Reply to file read operation
            if ( self.fileOpCode == COMMMESSAGE_FILEOPCODE_FILEREAD )
            {
                if ( self.receivedData.length < 4 )
                {
                    self.messageReplyStatus = MessageReplyStatusError;
                }
                else
                {
                    uint32_t readSize;
                    [self.receivedData getBytes:&readSize range:NSMakeRange(1,4)];
                    self.uncompressedSize = readSize;
                }
            }
            
            return TRUE;
        }
    }
    return  FALSE;
}

@end
