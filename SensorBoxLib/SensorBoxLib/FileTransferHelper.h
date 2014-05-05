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

#import <Foundation/Foundation.h>
#import "SensorBoxLib.h"

//! File Open Result code
enum {
    //! File Open was successful
    FileOpenSuccess = 0,
    //! File open failed due to missing File
    FileOpenFailureNotFound,
    //! A file is already open, close first
    FileOpenFailureAlreadyOpen,
    //! File Open with unspecified error
    FileOpenFailureUnknown
};
//! File open result
typedef NSInteger FileOpenResult;

//! File Close result. A failure can usually be ignored.
enum {
    //! File close was successful
    FileCloseSuccess = 0,
    //! File close filed because no file was open
    FileCloseFailureNotOpen,
    //! File close Unspecified error
    FileCloseFailureUnknown
};
//! File close result
typedef NSInteger FileCloseResult;

//! File read result/status. 
enum {
    //! File read has completed successfully
    FileReadSuccess = 0,
    //! File read in in progress
    FileReadInProgress,
    //! File read failed beacuse of sync issue (lost packets)
    FileReadFailureSync,
    //! File read failed because of timeout (no more packets received within timeout)
    FileReadFailureTimeout
};
//! File read result/status.
typedef NSInteger FileReadStatus;

//! File open modes. The modes specify if the file is openend for read or write and if compression is used.
enum {
    //! File is closed
    FileOpenModeClosed = 0x0000,
    //! File open in plain read mode
    FileOpenModeReadPlain = 0x0001,
    //! File open in IGC optimized Huffmann tree compression mode. This mode should only be used for ICG files.
    FileOpenModeReadIGCHuffmann = 0x0002
};
//! File open mode
typedef NSInteger FileOpenMode;

@protocol FileTransferHelperDelegate;

//! File transfer helper class
/**
 *  This class is automatically instantiated by SensorBox class and is used to 
 *  support the file transfer process.
 *  Before a file transfer can be initiated the SensorBox must be set into file transfer mode using 
 *  event code message. See protocol definition for details.
 *  The class can be used to list files in directory or to open and read files.
 *  The class receives messages directly from Communication Service and sends status messages to 
 *  its delegate.       
 *  Please refer to the protocol description for the full details on file transfer.
*/    
@interface FileTransferHelper : NSObject <CommunicationServiceFileHelperDelegate>

//! CommunicatioService linked to this Service
@property(assign,nonatomic) CommunicationService* commService;

//! Delegate to report updates to. Usually bound to client application
@property(nonatomic,assign) id <FileTransferHelperDelegate> delegate;

//! List of all files found during beginGetFiles. Wait for completion message before usage.
@property(retain,nonatomic) NSMutableArray* fileList;

//! File handle on SensBox for currently opened file.
@property(nonatomic) uint32_t fileHandle;

//! File name from last open command
@property(retain,nonatomic) NSString* fileName;

//! Destination file name for read operation (from last open command)
@property(retain,nonatomic) NSString* destFilename;

//! Destination file handle for file write operation
@property(retain,nonatomic) NSFileHandle* destFileHandle;

//! Internal packet reorder buffer to reorder incomming file packets
@property(retain,nonatomic) NSMutableArray* reorderBuffer;

//! Expected next packet number (internal use)
@property(nonatomic) uint8_t expectedNextData;

//! Timeout timer to detect interupted file transfer
@property(retain,nonatomic) NSTimer* timeoutTimer;

//! Timeout to detect interupted file transfer 
@property(retain,nonatomic) NSDate* timeoutDate;

//! Flag if folders should be included in file listing
@property(nonatomic) BOOL includeFolders;

//! Last error code received from the SensBox (for debugging purpose)
@property(nonatomic) uint8_t lastErrorCode;

//! Current open file mode. (From last file open command)
@property(nonatomic) FileOpenMode fileOpenMode;

//! Total file size of opened file
@property(nonatomic) NSInteger fileSizeTotal;

//! Remaining bytes to receive complete file
@property(nonatomic) NSInteger fileSizeRemaining;

//! Current CRC16 code of all received (decompressed) data. This can be used to compare with reported crc from SensBox in file close reply.
@property(nonatomic) unsigned short receivedDataCrc;

//! Internal buffer for decompression
@property(nonatomic) uint16_t compression_remainbuffer;

//! Number of bits in internal buffer for decompression
@property(nonatomic) uint8_t compression_remainbuffer_bitcount;


- (id) initWithCommunicationService: (CommunicationService*)inCommService;
- (void) beginGetFiles: (NSString*)folder includeFolders:(BOOL) inIncludeFolders;
- (void) openFile: (NSString*)filename mode:(FileOpenMode) mode;
- (void) closeFile;
- (void) abortTransfer;

//! Starts a file read on a open file
/**
 The recieved file is written to destinationFilename in the app's document folder on the iOS device.
 @sa startReadOpenFile:inDirectory:
 */
-(BOOL) startReadOpenFile:(NSString*)destinationFilename;
//! Starts a file read on a open file
/**
 Starts reading an opened file. The recieved file is written to destinationFilename in the
 destination directory on the iOS device. destinationFilename may not only contain a file name
 but also a relative path with respect to the specified directory. A CRC check can be performed after closing the file.
 Before the SensBox starts sending data the readFileReady delegate function is invoked.
 During file transfer and when finished the readFileProgress is invoked to report progess.
 Also, in case of no reply from the SensBox a timeoutWaitingResponse directly from
 CommunicationService could be invoked. During transfer a timeout would be reported
 through readFileProgress.
 @remarks If destinationDirectory is nil or empty it is assumed that destinationFilename contains
          a full path description for the output file. If destinationFilename is nil or empty no
          data will be read and NO will be returned.
 */
-(BOOL) startReadOpenFile:(NSString*)destinationFilename inDirectory:(NSString*)destinationDirectory;

@end


//! Delegate for filetransferhelper update callbacks
/**
 *  This delegate protocol is used to report changes from a Service in a SensorBox
 */
@protocol FileTransferHelperDelegate<NSObject>
@optional

//! Invoke upon completion of file listing
/** 
    This function is invoked upon completion of file listing. File listing is initiated using
    beginGetFiles.
    @param helper FileTransferHelper invoking
    @param fileList List of files (and directory if selected) inside the folder requested
*/  
-(void) getFilesFinished:(FileTransferHelper*)helper fileList:(NSMutableArray*) fileList;

//! Invoke upon completion of file open request
/** 
    This function is invoked upon completion of file open command. The result contains
    the success or error code. 
    @param helper FileTransferHelper invoking
    @param result File open result.
*/  
-(void) openFileFinished:(FileTransferHelper*)helper result:(FileOpenResult) result;

//! Invoke upon completion of file close request
/** 
    This function is invoked upon completion of file close command. The result contains
    the success or error code. Usually a failed close can be ignored as it mostly sais
    that no file was open on SensBox. In case of successful close the crc transmitted 
    from SensBox can be used to compare with the file helpers calculated receivedDataCrc.
    to check validity of the received file.  
    @param helper FileTransferHelper invoking
    @param result File close result.
    @param crc Received crc16 from SensBox
*/  
-(void) closeFileFinished:(FileTransferHelper*)helper result:(FileCloseResult) result crc:(uint16_t)crc;

//! Invoke upon readyness of file transfer
/** 
    This function is invoked upon file tranfer ready response from the SensBox.
    After this invoke the file helper will automatically start accepting notify and 
    thus receiving data.
    File transfer can be aborted using abortTransfer call.
    @param helper FileTransferHelper invoking
    @param size Size of the file to be received
*/  
-(void) readFileReady:(FileTransferHelper*)helper size:(NSInteger) size;

//! Invoke upon abort of file transfer
/** 
    This function is invoked as response to a abortTransfer call and when the 
    file transfer is successfully aborted.
    @param helper FileTransferHelper invoking
*/  
-(void) abortFinished:(FileTransferHelper*)helper;

//! File download progress update
/** 
    This function is regularly invoked during file transfer to report download 
    progress. This function also reports download error such as synchronization
    issue or timeout.
    Also, the function is called when all bytes have been received. In such case
    the client application must call closeFile function to close the file on the
    SensBox and to receive the crc16 from the SensBox.
    @param helper FileTransferHelper invoking
    @param result File transfer status
    @param progress Floating point progress. 0..1, 1 = 100%
*/  
-(void) readFileProgress:(FileTransferHelper*)helper result:(FileReadStatus) status progress:(float) progress;


@required
@end