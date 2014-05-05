//
//  CommMessageFile.h
//  SensorBoxLib
//
//  Created by Aimago/man 
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  07.11.2013   man    First Release


#import "CommMessage.h"
#import "FileInfoEntry.h"

//! File Control Message code
#define COMMMESSAGE_MSGCODE_FILE 0x03

//! File operation: Find first file in directory
#define COMMMESSAGE_FILEOPCODE_FINDFIRST 0x01
//! File operation: Find next file in directory
#define COMMMESSAGE_FILEOPCODE_FINDNEXT 0x02
//! File operation: Open file
#define COMMMESSAGE_FILEOPCODE_FILEOPEN 0x03
//! File operation: Close file
#define COMMMESSAGE_FILEOPCODE_FILECLOSE 0x04
//! File operation: Ready data from file
#define COMMMESSAGE_FILEOPCODE_FILEREAD 0x05
//! File operation: Abort transfer
#define COMMMESSAGE_FILEOPCODE_ABORT 0x07

//! File operation messsage couldn't be understood
#define COMMMESSAGE_FILEOP_ERROR_FILE_FORMAT_BAD		0x01
//! File operation is not ready. Make sure SensBox is in File Transfer Mode  
#define COMMMESSAGE_FILEOP_ERROR_FILE_STATE_NOTREADY  0x02
//! File or folder not found
#define COMMMESSAGE_FILEOP_ERROR_FILE_NOTFOUND    	0x03
//! A file is already open. Please close first.
#define COMMMESSAGE_FILEOP_ERROR_FILE_ISOPEN    		0x04
//! No file is open yet.
#define COMMMESSAGE_FILEOP_ERROR_FILE_NOTOPEN    		0x05
//! [Please specify]
#define COMMMESSAGE_FILEOP_ERROR_FILE_TIP		   		0x06
//! File name was empty
#define COMMMESSAGE_FILEOP_ERROR_FILE_NAME_EMPTY    	0x07


//! Structure for navigation characteristic
typedef struct {
    //! Uncompressed filesize in bytes
    uint32_t size;
    //! File date/time in unixtime format
    uint32_t time;
    //! Directory flag
    unsigned char filetype;
} comm_filelist_t;

//! Size of the file list in bytes. This is necessary as the struct will be 32-bit aligned
#define COMMMESSAGE_FILELIST_TYPE_SIZE 9


//! Message for file transfer control
/**
 *  This communication service message is used for file operation control. 
 *  It is used for all file messages such as open, close, list directory, etc.
 *  Some properties are only used for some specific file operations.   
*/  
@interface CommMessageFile : CommMessage

//! String to be sent for file open and list files
@property (retain,nonatomic) NSString* sendString;
//! File operation code for this message
@property(nonatomic) uint16_t fileOpCode;
//! File mode requested with this message
@property(nonatomic) uint16_t fileMode;
//! File handle requested or returned with this message
@property(nonatomic) uint32_t fileHandle;
//! Entry of file list (if file operation is list files)
@property(retain,nonatomic)  FileInfoEntry* fileInfoEntry;
//! CRC returned with this message
@property(nonatomic) uint16_t fileCrc;
//! Uncompressed file size returned by the message
@property(nonatomic) uint32_t uncompressedSize;
//! Error code returned by the message. 0 if none
@property(nonatomic) uint8_t errorCode;

- (id) initFindFileFirst: (NSString*)folder;
- (id) initFindFileNext;
- (id) initOpenFile: (NSString*)inFilename mode:(NSInteger) inMode;
- (id) initCloseFile: (uint32_t) handle;
- (id) initReadFile:(uint32_t)handle;
- (id) initAbort;

@end
