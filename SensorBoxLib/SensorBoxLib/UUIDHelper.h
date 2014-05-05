//
//  UUIDHelper.h
//  UUIDHelper
//
//  Created by Aimago/man 
//  Copyright (c) 2012 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  26.4.2012   man    First Release
//  06.6.2012   man    Finalize & Documentation


#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


//! Helper class for handling UUID's
/**
 *  This helper class only contains static functions that help converting between
 *  UUID's and other data types (UInt16 or NSString) or functions that compare
 *  two UUIDs.
*/    
@interface UUIDHelper : NSObject

+ (int) UUIDSAreEqual:(CFUUIDRef)u1 u2:(CFUUIDRef)u2;
+(NSString*) CBUUIDToString:(CBUUID *) UUID;
+(NSString*) UUIDToString:(CFUUIDRef)UUID;
+(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2;
+(int) compareCBUUIDToInt:(CBUUID *)UUID1 UUID2:(UInt16)UUID;
+(UInt16) CBUUIDToInt:(CBUUID *) UUID;
+(CBUUID *) IntToCBUUID:(UInt16)UUID;
+(CBUUID *) StringToCBUUID:(NSString*)UUID;

@end
