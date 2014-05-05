//
//  FileInfoEntry.h
//  SensorBoxLib
//
//  Created by Aimago/man 
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  07.11.2013   man    First Release


#import <Foundation/Foundation.h>

//! Item type of list entry. Can be file or folder
enum {
    //! Item is a file
    FileTypeFile = 1,
    //! Item is a folder
    FileTypeDirectory = 2
};

typedef NSUInteger FileType;

//! File listing entry 
/** 
 * This class represents a file listing entry which is returned by the 
 * file transfer helper upon listing of a folder.
*/   
@interface FileInfoEntry : NSObject

//! Size of the file in bytes
@property(nonatomic) NSUInteger sizeBytes;
//! Creation date & time of the file
@property(retain,nonatomic) NSDate* datetime;
//! Filename (only name within the folder without path)
@property(retain,nonatomic) NSString* filename;
//! If the entry is a file or directory
@property(nonatomic) FileType fileType;

- (id) initWithFilename: (NSString*)inFilename size:(uint32_t)inSize datetime:(uint32_t)inDateTime fileType:(unsigned char)inFileType;

@end
