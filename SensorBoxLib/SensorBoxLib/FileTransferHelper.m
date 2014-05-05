//
//  FileTransferHelper.m
//  SensorBoxLib
//
//  Created by Aimago/man 
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  07.11.2013   man    First Release
//  24.12.2013   man    Improved debug output handling

#import "FileTransferHelper.h"
#import "DebugManager.h"


//*************************************************************
//* 
//* Private C helper functions 
//* 
//*************************************************************


//**********************
//* Prototype definitions of C helper functions
//**********************

int huffmann_decompress(uint8_t* pinbuffer, uint16_t inbufferlen, uint8_t* poutbuffer, uint16_t* outbufferlen, uint16_t maxoutbufferlen, uint32_t expectedlen, uint16_t* pcompress_remainbuffer, uint8_t* pcompress_remainbuffer_bitcount);
int huffmann_decompress_char(uint16_t compressed, uint8_t compressed_bitlen, uint8_t* plain);
unsigned short crc16_ccitt(const void *buf, int len);
unsigned short crc16_ccitt_append(unsigned short crc, const void *buf, int len);
unsigned short crc16_ccitt_appendbyte(unsigned short crc, char byte);

//********************
//* Compression
//********************

// Decompress a char
// Takes 2-16 bits from the input stream
// Returns number of bits used. -1 = invalid bit combination, 0=not enough bits for a valid next char
int huffmann_decompress_char(uint16_t compressed, uint8_t compressed_bitlen, uint8_t* plain)
{
	if ( compressed_bitlen < 2 ) return 0;
	switch ( compressed & 0xc000 )
	{
	case 0xc000:
		*plain = '0';
		return 2;
	}

	if ( compressed_bitlen < 3 ) return 0;
	switch ( compressed & 0xe000 )
	{
	case 0x4000:
		*plain = '1';
		return 3;
	case 0x0000:
		*plain = '9';
		return 3;
	}

	if ( compressed_bitlen < 4 ) return 0;
	switch ( compressed & 0xf000 )
	{
	case 0x2000:
		*plain = '3';
		return 4;
	case 0x9000:
		*plain = '4';
		return 4;
	case 0x7000:
		*plain = '6';
		return 4;
	case 0x3000:
		*plain = '7';
		return 4;
	}

	if ( compressed_bitlen < 5 ) return 0;
	switch ( compressed & 0xf800 )
	{
	case 0x6000:
		*plain = '-';
		return 5;
	case 0xb000:
		*plain = '2';
		return 5;
	case 0xb800:
		*plain = '5';
		return 5;
	case 0xa800:
		*plain = '8';
		return 5;
	}

	if ( compressed_bitlen < 6 ) return 0;
	switch ( compressed & 0xfc00 )
	{
	case 0x8c00:
		*plain = 13;
		return 6;
	case 0xa000:
		*plain = 10;
		return 6;
	case 0x6800:
		*plain = 'B';
		return 6;
	case 0x8800:
		*plain = 'E';
		return 6;
	case 0x8000:
		*plain = 'N';
		return 6;
	case 0x6c00:
		*plain = 'S';
		return 6;
	case 0x8400:
		*plain = 'W';
		return 6;
	}

	if ( compressed_bitlen < 7 ) return 0;
	switch ( compressed & 0xfe00 )
	{
	case 0xa600:
		*plain = 'A';
		return 7;
	}

	if ( compressed_bitlen < 8 ) return 0;
	switch ( compressed & 0xff00 )
	{
	case 0xa500:
		*plain = 'V';
		return 8;
	}

	if ( compressed_bitlen < 16 ) return 0;
	if ( ( compressed & 0xff00 ) == 0xa400 )
	{
		*plain = compressed & 0xff;
		return 16;
	}
	return -1;
}


// Decompress from the bit stream
// maxoutbufferlen is a hard limit to make sure we don't overrun the outbufferlen. If this is 4*inbufferlen+1 it should never happen
// expectedlen stops when the end of the file is reached. This is necessary as the decompressor can't detect end of the file
int huffmann_decompress(uint8_t* pinbuffer, uint16_t inbufferlen, uint8_t* poutbuffer, uint16_t* outbufferlen, uint16_t maxoutbufferlen, uint32_t expectedlen, uint16_t* pcompress_remainbuffer, uint8_t* pcompress_remainbuffer_bitcount)
{
	// Copy stuff from the remainer buffer
	uint8_t* pin = pinbuffer;
	uint8_t* pout = poutbuffer;
	uint32_t tmpbuffer = ((uint32_t)*pcompress_remainbuffer<<8);
	int tmp_buffer_bitcount = *pcompress_remainbuffer_bitcount;
	int result = 1;
	*outbufferlen = 0;

	// Process until we don't have new bytes or the output len is limited
	while(result >= 0 && *outbufferlen < maxoutbufferlen && *outbufferlen < expectedlen && inbufferlen > 0)
	{
		// Fill buffer to hold at least 16 bits
		int remain = 16 - tmp_buffer_bitcount;
		while ( remain > 0 )
		{
			tmpbuffer |= (((uint32_t)*pin) << (16-tmp_buffer_bitcount));
			tmp_buffer_bitcount+= 8;
			pin++;
			inbufferlen--;
			if ( inbufferlen == 0 ) break;
			remain -= 8;
		}

		// Process buffer and decompress chars
		int result = 1;
		while ( result > 0 && *outbufferlen < maxoutbufferlen && *outbufferlen < expectedlen )
		{
			*pcompress_remainbuffer = (uint16_t)(tmpbuffer >> 8);
			*pcompress_remainbuffer_bitcount = tmp_buffer_bitcount;
			if ( *pcompress_remainbuffer_bitcount > 16 ) *pcompress_remainbuffer_bitcount = 16;
			result = huffmann_decompress_char(*pcompress_remainbuffer, *pcompress_remainbuffer_bitcount, pout);

			// A char was decompressed. Move the output buffer
			if ( result > 0 )
			{
				pout++;
				tmpbuffer <<= result;
				tmpbuffer &= 0xffffff;
				tmp_buffer_bitcount -= result;
				(*outbufferlen)++;
			}
		}
	}

	// Save remaining bits
	*pcompress_remainbuffer = (uint16_t)(tmpbuffer >> 8);
	*pcompress_remainbuffer_bitcount = tmp_buffer_bitcount;

	if ( result > 0 ) result = 0;
	if ( *outbufferlen == maxoutbufferlen ) result = -3;
	return result;
}

/*******************************************************
 *** CRC
 *******************************************************/

// CRC16 implementation acording to CCITT standards

static const unsigned short crc16tab[256]= {
	0x0000,0x1021,0x2042,0x3063,0x4084,0x50a5,0x60c6,0x70e7,
	0x8108,0x9129,0xa14a,0xb16b,0xc18c,0xd1ad,0xe1ce,0xf1ef,
	0x1231,0x0210,0x3273,0x2252,0x52b5,0x4294,0x72f7,0x62d6,
	0x9339,0x8318,0xb37b,0xa35a,0xd3bd,0xc39c,0xf3ff,0xe3de,
	0x2462,0x3443,0x0420,0x1401,0x64e6,0x74c7,0x44a4,0x5485,
	0xa56a,0xb54b,0x8528,0x9509,0xe5ee,0xf5cf,0xc5ac,0xd58d,
	0x3653,0x2672,0x1611,0x0630,0x76d7,0x66f6,0x5695,0x46b4,
	0xb75b,0xa77a,0x9719,0x8738,0xf7df,0xe7fe,0xd79d,0xc7bc,
	0x48c4,0x58e5,0x6886,0x78a7,0x0840,0x1861,0x2802,0x3823,
	0xc9cc,0xd9ed,0xe98e,0xf9af,0x8948,0x9969,0xa90a,0xb92b,
	0x5af5,0x4ad4,0x7ab7,0x6a96,0x1a71,0x0a50,0x3a33,0x2a12,
	0xdbfd,0xcbdc,0xfbbf,0xeb9e,0x9b79,0x8b58,0xbb3b,0xab1a,
	0x6ca6,0x7c87,0x4ce4,0x5cc5,0x2c22,0x3c03,0x0c60,0x1c41,
	0xedae,0xfd8f,0xcdec,0xddcd,0xad2a,0xbd0b,0x8d68,0x9d49,
	0x7e97,0x6eb6,0x5ed5,0x4ef4,0x3e13,0x2e32,0x1e51,0x0e70,
	0xff9f,0xefbe,0xdfdd,0xcffc,0xbf1b,0xaf3a,0x9f59,0x8f78,
	0x9188,0x81a9,0xb1ca,0xa1eb,0xd10c,0xc12d,0xf14e,0xe16f,
	0x1080,0x00a1,0x30c2,0x20e3,0x5004,0x4025,0x7046,0x6067,
	0x83b9,0x9398,0xa3fb,0xb3da,0xc33d,0xd31c,0xe37f,0xf35e,
	0x02b1,0x1290,0x22f3,0x32d2,0x4235,0x5214,0x6277,0x7256,
	0xb5ea,0xa5cb,0x95a8,0x8589,0xf56e,0xe54f,0xd52c,0xc50d,
	0x34e2,0x24c3,0x14a0,0x0481,0x7466,0x6447,0x5424,0x4405,
	0xa7db,0xb7fa,0x8799,0x97b8,0xe75f,0xf77e,0xc71d,0xd73c,
	0x26d3,0x36f2,0x0691,0x16b0,0x6657,0x7676,0x4615,0x5634,
	0xd94c,0xc96d,0xf90e,0xe92f,0x99c8,0x89e9,0xb98a,0xa9ab,
	0x5844,0x4865,0x7806,0x6827,0x18c0,0x08e1,0x3882,0x28a3,
	0xcb7d,0xdb5c,0xeb3f,0xfb1e,0x8bf9,0x9bd8,0xabbb,0xbb9a,
	0x4a75,0x5a54,0x6a37,0x7a16,0x0af1,0x1ad0,0x2ab3,0x3a92,
	0xfd2e,0xed0f,0xdd6c,0xcd4d,0xbdaa,0xad8b,0x9de8,0x8dc9,
	0x7c26,0x6c07,0x5c64,0x4c45,0x3ca2,0x2c83,0x1ce0,0x0cc1,
	0xef1f,0xff3e,0xcf5d,0xdf7c,0xaf9b,0xbfba,0x8fd9,0x9ff8,
	0x6e17,0x7e36,0x4e55,0x5e74,0x2e93,0x3eb2,0x0ed1,0x1ef0
};

unsigned short crc16_ccitt(const void *buf, int len)
{
	register int counter;
	register unsigned short crc = 0;
	for( counter = 0; counter < len; counter++)
		crc = (crc<<8) ^ crc16tab[((crc>>8) ^ *(char *)buf++)&0x00FF];
	return crc;
}

unsigned short crc16_ccitt_append(unsigned short crc, const void *buf, int len)
{
	register int counter;
	for( counter = 0; counter < len; counter++)
		crc = (crc<<8) ^ crc16tab[((crc>>8) ^ *(char *)buf++)&0x00FF];
	return crc;
}
unsigned short crc16_ccitt_appendbyte(unsigned short crc, char byte)
{
	crc = (crc<<8) ^ crc16tab[((crc>>8) ^ byte)&0x00FF];
	return crc;
}

@implementation FileTransferHelper

@synthesize commService;
@synthesize fileHandle;
@synthesize delegate;
@synthesize fileList;
@synthesize fileName;
@synthesize includeFolders;
@synthesize lastErrorCode;
@synthesize fileSizeRemaining;
@synthesize fileSizeTotal;
@synthesize destFilename;
@synthesize destFileHandle;
@synthesize expectedNextData;
@synthesize reorderBuffer;
@synthesize timeoutTimer;
@synthesize timeoutDate;


//*************************************************************
//* 
//* Private Functions 
//* 
//*************************************************************

//! Will be called on dispose of the object
- (void) dealloc
{
    if ( self.timeoutTimer != nil )
    {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
    
    if ( self.commService != nil ) self.commService.fileHelperDelegate = nil;
    self.commService = nil;
    self.fileList = nil;
    self.destFileHandle = nil;
    self.destFilename = nil;
    self.delegate = nil;
    self.fileName = nil;
    self.reorderBuffer = nil;
    self.timeoutDate = nil;
    self.reorderBuffer = nil;

    [super dealloc];
}

//! Writes received data to file
/** 
    This function is called when received file data is parsed and to be written
    to the file. The function decompresses the data if needed (depending on
    fileOpenMode) and writes it to the open file.
    The function also updates the CRC and the reainingFileSize.
  
    @param data Data received and to be written
    @return Returns number of bytes written
*/
-(int) writeChunkToFile:(NSData*) data
{
    uint16_t size = 0;
    unsigned char tmp[82];
    
    if ( self.fileOpenMode == FileOpenModeReadIGCHuffmann )
    {
        // Huffmann compression
        // Optimized for IGC files
        unsigned char tmp2[20];
        uint8_t rbitcount = self.compression_remainbuffer_bitcount;
        uint16_t rbuf = self.compression_remainbuffer;
        [data getBytes:&tmp2];
        
        huffmann_decompress(tmp2, data.length, tmp, &size, 82, self.fileSizeRemaining, &rbuf, &rbitcount);
        self.compression_remainbuffer = rbuf;
        self.compression_remainbuffer_bitcount = rbitcount;
        if ( size > 0 )
        {
            NSData* data2 = [[[NSData alloc] initWithBytes:tmp length:size] autorelease];
            if ( self.destFileHandle != nil )
            {
                [self.destFileHandle writeData:data2];
            }
        }
    }
    else
    {
        // Uncompressed
        [data getBytes:&tmp];
        
        if ( self.destFileHandle != nil )
        {
            [self.destFileHandle writeData:data];
        }
        size = data.length;
    }

    self.fileSizeRemaining -= size;
    self.receivedDataCrc = crc16_ccitt_append(self.receivedDataCrc, tmp, size);
    
    return size;
}

//! Event exectued by timeout timer to check if data is overdue
/** 
    This function is called during file receive and checks if the last data received
    is within the defined timeout. 
    If timeout occured it aborts the transfer.
  
    @param timer Timeout timer
*/
-(void) handleTimoutTimer:(NSTimer*)timer
{
    if ( self.timeoutDate != nil && [self.timeoutDate compare:[NSDate date]] == NSOrderedAscending )
    {
        [self abortTransfer];
        
        // Timeout!
        if ( self.destFileHandle != nil )
        {
            [self.destFileHandle closeFile];
            self.destFileHandle = nil;
        }
        if ( self.timeoutTimer != nil )
        {
            [self.timeoutTimer invalidate];
            self.timeoutTimer = nil;
        }
        
        NSInteger p = 1.0 - ((float)self.fileSizeRemaining / (float)self.fileSizeTotal);
        if ([[self delegate] respondsToSelector:@selector(readFileProgress:result:progress:)])
					[[self delegate] readFileProgress:self result:FileReadFailureTimeout progress:p];
    }
}

//*************************************************************
//* 
//* Callback from CBPeripheralDelegate. Private functions.
//*
//*************************************************************

//! Invoked by CommuniciationService when file data is received
/** 
    This function is invoked when the CommunicationService received new file data.
    The file data is parsed and sorted by this function. If file read is completed
    the function terminates the file transfer and sends success message.
    
    @param service Communcation Service invoking the function.
    @param data Data received and to be parsed.
*/      
-(void) fileChunkReceived:(CommunicationService*)service data:(NSData*) data
{
    self.timeoutDate = [[[NSDate alloc] initWithTimeIntervalSinceNow:3] autorelease];
    
    if ( self.destFileHandle == nil )
    {
        [DebugManager writeDebugLogWithLevel:DebugLevelInfo messsage:@"received FILETRANSFER, but file closed. ignore."];
        return;
    }
    
    uint8_t dataNo = 0;
    [data getBytes:&dataNo length:1];
    
    if ( dataNo == self.expectedNextData )
    {
        
        [self writeChunkToFile: [data subdataWithRange:NSMakeRange(1, data.length-1)]];
    
        [DebugManager writeDebugLogWithLevel:DebugLevelVerbose messsage:@"received FILETRANSFER, remain: %i, no %i expected %i", self.fileSizeRemaining, dataNo, self.expectedNextData];

        self.expectedNextData++;
        
        // Do we have the next in our buffer?
        BOOL found = true;
        while ( found )
        {
            found = false;
            for ( int i=0; i<self.reorderBuffer.count; i++ )
            {
                NSData* d = [self.reorderBuffer objectAtIndex:i];
                char t[20];
                [d getBytes:&t];
                
                [d getBytes:&dataNo length:1];
                if ( dataNo == self.expectedNextData )
                {
                    [DebugManager writeDebugLogWithLevel:DebugLevelVerbose messsage:@"Removed from buffer: %i", dataNo];

                    [self writeChunkToFile: [d subdataWithRange:NSMakeRange(1, d.length-1)]];
                    
                    [self.reorderBuffer removeObjectAtIndex:i];
                    found = true;
                    self.expectedNextData++;
                    break;
                }
            }
        }
    }
    else
    {
        [DebugManager writeDebugLogWithLevel:DebugLevelVerbose messsage:@"received FILETRANSFER, remain: %i, no %i expected %i", self.fileSizeRemaining, dataNo, self.expectedNextData];

        if ( self.reorderBuffer.count > 20 )
        {
            [DebugManager writeDebugLogWithLevel:DebugLevelErrors messsage:@"Too many items in reorder buffer. Out of sync."];
            [self abortTransfer];
            
            // This shouldn't happen. Probably lost data. Abort
            if ( self.timeoutTimer != nil )
            {
                [self.timeoutTimer invalidate];
                self.timeoutTimer = nil;
            }
            if ( self.destFileHandle != nil )
            {
                [self.destFileHandle closeFile];
                self.destFileHandle = nil;
            }
            
            NSInteger p = 1.0 - ((float)self.fileSizeRemaining / (float)self.fileSizeTotal);
					
            if ([[self delegate] respondsToSelector:@selector(readFileProgress:result:progress:)])
							[[self delegate] readFileProgress:self result:FileReadFailureSync progress:p];
            
            return;
        }
        
        [DebugManager writeDebugLogWithLevel:DebugLevelVerbose messsage:@"Added to reorderbuffer: %i", dataNo];
        // Out of sync
        [self.reorderBuffer addObject:data];
    }
    
    
    if ( self.fileSizeRemaining == 0 )
    {
        self.timeoutDate = nil;
        if ( self.timeoutTimer != nil )
        {
            [self.timeoutTimer invalidate];
            self.timeoutTimer = nil;
        }
        
        [self.destFileHandle closeFile];
        self.destFileHandle = nil;
        [self.commService setFileNotify:NO];
        
        if ([[self delegate] respondsToSelector:@selector(readFileProgress:result:progress:)])
					[[self delegate] readFileProgress:self result:FileReadSuccess progress:1.0];
        
        [DebugManager writeDebugLogWithLevel:DebugLevelInfo messsage:@"Received full file. closed file"];
    }
    else
    {
			float p = 1.0 - ((float)self.fileSizeRemaining / (float)self.fileSizeTotal);

			if ([[self delegate] respondsToSelector:@selector(readFileProgress:result:progress:)])
        [[self delegate] readFileProgress:self result:FileReadInProgress progress:p];
    }
}

//! Invoked by CommuniciationService when control message reply is received
/** 
    This function is invoked when the CommunicationService received a control message
    reply. This process is handled by the underlying infrastructure of CommunicationService.
    The message is parsed and corresponding action (such as sending notice to delegate)
    is performde.
    
    @param service Communcation Service invoking the function.
    @param message Message received
*/   
-(void) messageReceived:(CommunicationService*)service message:(CommMessage*) message
{
    if ( ! [ message isKindOfClass:[CommMessageFile class]] ) return;
    
    CommMessageFile* msgFile = (CommMessageFile*)message;
    self.lastErrorCode = msgFile.errorCode;
    
    if ( msgFile.fileOpCode == COMMMESSAGE_FILEOPCODE_FINDFIRST || msgFile.fileOpCode == COMMMESSAGE_FILEOPCODE_FINDNEXT )
    {
        if ( msgFile.messageReplyStatus == MessageReplyStatusAck)
        {
            // At the file to our list
            if ( self.includeFolders || msgFile.fileInfoEntry.fileType == FileTypeFile )
            {
                [self.fileList addObject:[[msgFile.fileInfoEntry retain] autorelease]];
            }
        
            // Request next file
            CommMessageFile* msg2 = [[[CommMessageFile alloc] initFindFileNext] autorelease];
            [self.commService sendMessage:msg2];
        }
        else
        {
            // We are done
					if ([[self delegate] respondsToSelector:@selector(getFilesFinished:fileList:)])
            [self.delegate getFilesFinished:self fileList:self.fileList];
        }
    }
    
    if ( msgFile.fileOpCode == COMMMESSAGE_FILEOPCODE_FILEOPEN )
    {
        FileOpenResult result = FileOpenFailureUnknown;
        if ( msgFile.messageReplyStatus == MessageReplyStatusAck)
        {
            self.fileHandle = msgFile.fileHandle;
            result = FileOpenSuccess;
        }
        else
        {
            if ( msgFile.errorCode == COMMMESSAGE_FILEOP_ERROR_FILE_NOTFOUND ) result = FileOpenFailureNotFound;
            if ( msgFile.errorCode == COMMMESSAGE_FILEOP_ERROR_FILE_ISOPEN ) result = FileOpenFailureAlreadyOpen;
        }
        
        [DebugManager writeDebugLogWithLevel:DebugLevelInfo messsage:@"File opened: %i, %i", result, self.lastErrorCode];
				if ([[self delegate] respondsToSelector:@selector(openFileFinished:result:)])
	        [[self delegate] openFileFinished:self result:result];
    }
    
    if ( msgFile.fileOpCode == COMMMESSAGE_FILEOPCODE_FILECLOSE )
    {
        FileCloseResult result = FileCloseFailureUnknown;
        uint16_t crc = 0;
        if ( msgFile.messageReplyStatus == MessageReplyStatusAck )
        {
            crc = msgFile.fileCrc;
            result = FileCloseSuccess;
        }
        else
        {
            if ( msgFile.errorCode == COMMMESSAGE_FILEOP_ERROR_FILE_NOTOPEN ) result = FileCloseFailureNotOpen;
        }
        
        self.fileOpenMode = FileOpenModeClosed;
        [DebugManager writeDebugLogWithLevel:DebugLevelVerbose messsage:@"File closed: %i, %i", result, self.lastErrorCode];
			  if ([[self delegate] respondsToSelector:@selector(closeFileFinished:result:crc:)])
	        [[self delegate] closeFileFinished:self result:result crc:crc];
    }
    
    if ( msgFile.fileOpCode == COMMMESSAGE_FILEOPCODE_FILEREAD )
    {
        NSInteger size = -1;

        if ( msgFile.messageReplyStatus == MessageReplyStatusAck )
        {
            size = msgFile.uncompressedSize;
        }
    
        // Clean any buffers
        self.fileSizeRemaining = size;
        self.fileSizeTotal = size;
        self.expectedNextData = 0;
        self.receivedDataCrc = 0;
        self.reorderBuffer = nil;
        self.reorderBuffer = [[[NSMutableArray alloc] init] autorelease];
        self.compression_remainbuffer_bitcount = 0;
        
        [DebugManager writeDebugLogWithLevel:DebugLevelInfo messsage:@"Read started. size: %i, %i", size, self.lastErrorCode];
				if ([[self delegate] respondsToSelector:@selector(readFileReady:size:)])
       	 [[self delegate] readFileReady:self size:size];
        
        if ( size == 0 )
        {
            [DebugManager writeDebugLogWithLevel:DebugLevelInfo messsage:@"Received zero sized file"];
            // Zero sized file. Write an emty file and close it
            self.timeoutDate = nil;
            if ( self.timeoutTimer != nil )
            {
                [self.timeoutTimer invalidate];
                self.timeoutTimer = nil;
            }
            
            [self.destFileHandle closeFile];
            self.destFileHandle = nil;
            [self.commService setFileNotify:NO];
          
            if ([[self delegate] respondsToSelector:@selector(readFileProgress:result:progress:)])
							[[self delegate] readFileProgress:self result:FileReadSuccess progress:1.0];
        }
        else if ( size > 0 )
        {
            [self.commService setFileNotify:YES];
        }
    }
    
    if ( msgFile.fileOpCode == COMMMESSAGE_FILEOPCODE_ABORT )
    {
			[DebugManager writeDebugLogWithLevel:DebugLevelInfo messsage:@"Abort finished"];
			if ([[self delegate] respondsToSelector:(@selector(abortFinished:))])
        [[self delegate] abortFinished:self];
    }
}

//*************************************************************
//* 
//* Public functions
//*
//*************************************************************

//! Initialize the object 
/** 
    Initialize the object using communication service. The class automatically
    sets itself as delegate to the communication service. 
    
    @param inCommService Communcation Service 
*/   
- (id) initWithCommunicationService:(CommunicationService *)inCommService
{
    self = [super init];
    
    if ( self )
    {
        self.commService = inCommService;
        inCommService.fileHelperDelegate = self;
    }
    
    return self;
}

//! Starts retrieving file list of a given folder
/** 
    Starts retrieving file list of a given folder. It can be specified if folders
    should also be listed. The process can take several seconds and will finish with
    invoking getFilesFinished. Also, in case of no reply from the SensBox a timeoutWaitingResponse
    directly from CommunicationService could be invoked. 
    Do not use fileList before the getFilesFinished is invoked.   
    
    @param folder String of folder to be listed. This can be a nested folder. Use forward slash to separate folder levels.
    @param inIncludeFolders False if only files and not subfolders should be listed
*/   
- (void) beginGetFiles: (NSString*)folder includeFolders:(BOOL) inIncludeFolders;
{
    CommMessageFile* msg = [[[CommMessageFile alloc] initFindFileFirst:folder] autorelease];
    
    self.fileList = [[[NSMutableArray alloc] init] autorelease];
    self.includeFolders = inIncludeFolders;

    [self.commService sendMessage:msg];
}

//! Opens a file on SensBox
/** 
    Opens a file on the SensBox for read or write operation (write not yet implemented).
    Only one file can be opened at the time.
    The successful open is reported using openFileFinished invoke.
    Also, in case of no reply from the SensBox a timeoutWaitingResponse directly from
    CommunicationService could be invoked. 
    
    @param filename Full path filename to open. Use forward slash to separate folder levels.
    @param mode Read or write open mode.
*/   
- (void) openFile: (NSString*)filename mode:(FileOpenMode) mode
{
    //if ( self.fileHandle != 0 ) return false;
    
    CommMessageFile* msg = [[[CommMessageFile alloc] initOpenFile:filename mode:mode] autorelease];
    self.fileName = filename;
    self.fileOpenMode = mode;
    
    [self.commService sendMessage:msg];
}

//! Closes a file on SensBox
/** 
    Closes a file on the Sensbox.
    The successful close is reported using closeFileFinished invoke.
    Also, in case of no reply from the SensBox a timeoutWaitingResponse directly from
    CommunicationService could be invoked. 
*/   
- (void) closeFile
{
    //if ( self.fileHandle == 0 ) return false;
    uint32_t handle = self.fileHandle;
    CommMessageFile* msg = [[[CommMessageFile alloc] initCloseFile:handle] autorelease];
    [self.commService sendMessage:msg];
}

//! Aborts a running file transfer
/** 
    Aborts a running file transfer.
    The successful abort is reported using abortFinished invoke.
    Also, in case of no reply from the SensBox a timeoutWaitingResponse directly from
    CommunicationService could be invoked. 
*/   
- (void) abortTransfer
{
    [self.commService setFileNotify:NO];
    
    if ( self.timeoutTimer != nil )
    {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
    if ( self.destFileHandle != nil )
    {
        [self.destFileHandle closeFile];
        self.destFileHandle = nil;
    }
    
    CommMessageFile* msg = [[[CommMessageFile alloc] initAbort] autorelease];
    [self.commService sendMessage:msg];
}

-(BOOL) startReadOpenFile:(NSString*)destinationFilename
{
	return [self startReadOpenFile:destinationFilename inDirectory:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) lastObject]];
}

-(BOOL) startReadOpenFile:(NSString*)destinationFilename inDirectory:(NSString*)destinationDirectory
{
	if (([destinationFilename length] == 0) || ([self fileHandle] == 0))
		return NO;
	
	NSFileManager* const fileManager = [NSFileManager defaultManager];
	
	if ([destinationDirectory length] > 0)
		[self setDestFilename:[destinationDirectory stringByAppendingPathComponent:destinationFilename]];
	else
		[self setDestFilename:destinationFilename];
	if ([fileManager createFileAtPath:[self destFilename] contents:nil attributes:nil])
	{
		[self setDestFileHandle:[NSFileHandle fileHandleForWritingAtPath:[self destFilename]]];
		[self setFileSizeRemaining:0];
		[self setFileSizeTotal:0];
    [self setTimeoutDate:[NSDate dateWithTimeIntervalSinceNow:3]];
		[self setTimeoutTimer:[NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(handleTimoutTimer:) userInfo:nil repeats:YES]];
		
		[[self commService] sendMessage:[[[CommMessageFile alloc] initReadFile:[self fileHandle]] autorelease]];
		
		return YES;
	} /* if */
	else
		return NO;
}

@end
