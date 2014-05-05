//
//  UUIDHelper.m
//  UUIDHelper
//
//  Created by Aimago/man 
//  Copyright (c) 2012 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  26.4.2012   man    First Release
//  06.6.2012   man    Finalize & Documentation


#import "UUIDHelper.h"

@implementation UUIDHelper

//*************************************************************
//* 
//* Private Functions first
//* 
//*************************************************************


//! byteswaps a Uint16
/**  
    @param s Uint16 value to byteswap

    @return Byteswapped UInt16
*/
+(UInt16) swap:(UInt16)s {
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}






//*************************************************************
//* 
//* Public Functions 
//* 
//*************************************************************


//! compares two CFUUIDRef's 
/**
    @param u1 CFUUIDRef 1 to compare
    @param u2 CFUUIDRef 2 to compare
  
    @returns 1 (equal) 0 (not equal)
*/
+ (int) UUIDSAreEqual:(CFUUIDRef)u1 u2:(CFUUIDRef)u2 {
    if ( u1 && u2 )
    {
        CFUUIDBytes b1 = CFUUIDGetUUIDBytes(u1);
        CFUUIDBytes b2 = CFUUIDGetUUIDBytes(u2);
        if (memcmp(&b1, &b2, 16) == 0) {
            return 1;
        }
        else return 0;
    }
    else return 0;
}


//! Converts CBUUID to a NSString
/**
    CBUUIDToString converts the data of a CBUUID class to a character pointer for easy printout using printf()
    
    @param UUID UUID to convert to string
 
    @returns Pointer to a character buffer containing UUID in string representation
*/
+(NSString*) CBUUIDToString:(CBUUID *) UUID {
    return [UUID.data description];
}


//! Converts CFUUIDRef to a NSString
/**
 *  UUIDToString converts the data of a CFUUIDRef class to a character pointer for easy printout using printf()
 *
 *  @param UUID UUID to convert to string
 *
 *  @returns Pointer to a character buffer containing UUID in string representation
 *
*/
+(NSString*) UUIDToString:(CFUUIDRef)UUID {
    if (!UUID) return @"NULL";
    CFStringRef s = CFUUIDCreateString(NULL, UUID);
    return [(NSString *)s autorelease];
    
}

//! compares two CBUUID's
/**
 *  compareCBUUID compares two CBUUID's to each other and returns 1 if they are equal and 0 if they are not
 *
 *  @param UUID1 UUID 1 to compare
 *  @param UUID2 UUID 2 to compare
 *
 *  @returns 1 (equal) 0 (not equal)
*/
+(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2 {
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1];
    [UUID2.data getBytes:b2];
    if (memcmp(b1, b2, UUID1.data.length) == 0)return 1;
    else return 0;
}

//! compares a CBUUID to a UInt16
/**
 *  compareCBUUIDToInt compares a CBUUID to a UInt16 representation of a UUID and returns 1 
 *  if they are equal and 0 if they are not
 *
 *  @param UUID1 UUID 1 to compare (should be 16-bit UUID)
 *  @param UUID2 UInt16 UUID 2 to compare
 *
 *  @returns 1 (equal) 0 (not equal)
*/
+(int) compareCBUUIDToInt:(CBUUID *)UUID1 UUID2:(UInt16)UUID2 {
    char b1[16];
    [UUID1.data getBytes:b1];
    UInt16 b2 = [self swap:UUID2];
    if (memcmp(b1, (char *)&b2, 2) == 0) return 1;
    else return 0;
}

//! converts a CBUUID to a UInt16
/**
 *  CBUUIDToInt converts a CBUUID (16-bit version) to a Uint16 representation of the UUID
 *
 *  @param UUID UUID 1 to convert
 *
 *  @returns UInt16 representation of the CBUUID
*/
+(UInt16) CBUUIDToInt:(CBUUID *) UUID {
    char b1[16];
    [UUID.data getBytes:b1];
    return ((b1[0] << 8) | b1[1]);
}

//! Converts a Int16 to a CBUUID
/**
 *  IntToCBUUID converts a UInt16 UUID to a CBUUID
 *
 *  @param UUID UInt16 representation of a UUID
 *
 *  @return The converted CBUUID
*/
+(CBUUID *) IntToCBUUID:(UInt16)UUID {
    char t[16];
    t[0] = ((UUID >> 8) & 0xff); t[1] = (UUID & 0xff);
    NSData *data = [[[NSData alloc] initWithBytes:t length:16] autorelease];
    return [CBUUID UUIDWithData:data];
}

//! Converts a NSString to a 128-bit CBUUID
/**
 *  This function converts a NSString to a CBUUID. The NSString can be formatted in any way
 *  as long as it contains 16 hexadecimal characters (0..9 | a..f). The first characters are used.
 *  All other characters are ignored. 
 *  A example formating could be the format that CBUUIDToString returns <aba27100 143b4b81 a444edcd 0000f020>
 *  The function returns nil if the conversion failed.
 *  
 * @param UUID NSString to be converted. See remarks.
 * @returns converted CBUUID or nil if function failed.          
*/   
+(CBUUID *) StringToCBUUID:(NSString*)UUID {
    char t[16];
    int i=0;
    int p=0;
    BOOL upperbyte = TRUE;
    while (p < 16 && i < UUID.length)
    {
        unichar c;
        [UUID getCharacters:&c range:NSMakeRange(i++,1)];
        char d = 127;
        if ( c >= 'a' && c <= 'f' ) d = c - 'a' + 10;
        if ( c >= 'A' && c <= 'F' ) d = c - 'A' + 10;
        if ( c >= '0' && c <= '9' ) d = c - '0';
        if ( d < 16 ) 
        {
            if ( upperbyte ) {
                t[p] = (d & 0x0f) << 4;
            }
            else {
                t[p] |= (d & 0x0f);
                p++;
            }
            upperbyte = !upperbyte;
        }
    }
    if ( p == 16 ) {
        NSData *data = [[NSData alloc] initWithBytes:t length:16];
        return [CBUUID UUIDWithData:data];
    }
    else {
        return nil;
    }
}

@end
