//  FileInfoEntry.m
//  SensorBoxLib
//
//  Created by Aimago/man 
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  07.11.2013   man    First Release

#import "FileInfoEntry.h"

@implementation FileInfoEntry

@synthesize sizeBytes;
@synthesize datetime;
@synthesize filename;
@synthesize fileType;


//*************************************************************
//* 
//* Private functions first
//*
//*************************************************************

//! Will be called on dispose of the object
- (void) dealloc
{
    self.filename = nil;
    self.datetime = nil;
    
    [super dealloc];
}


//*************************************************************
//* 
//* Public functions
//*
//*************************************************************

//! Initialize the optection using all paramters
/**
 * This function initializes the object using all required paramters.
 * @param inFilename Filename (usually without path)
 * @param inSize Size of the file in bytes
 * @param inDateTime unix date time of the file
 * @param inFylteType File type (file or directory)
*/       
- (id) initWithFilename: (NSString*)inFilename size:(uint32_t)inSize datetime:(uint32_t)inDateTime fileType:(unsigned char)inFileType
{
    self = [super init];
    if ( self )
    {
        
        self.filename = inFilename;
        self.sizeBytes = inSize;
        self.datetime = [[[NSDate alloc] initWithTimeIntervalSince1970:inDateTime] autorelease];
        self.fileType = inFileType;
        
    }
    
    return self;
}


@end
