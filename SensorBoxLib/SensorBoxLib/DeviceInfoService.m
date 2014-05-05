//
//  DeviceInfoService.m
//  SensorBoxLib
//
//  Created by Aimago/man 
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  26.4.2012   man    First Release
//  06.6.2012   man    Finalize & Documentation


#import "DeviceInfoService.h"
#import "UUIDHelper.h"

@implementation DeviceInfoService

//*************************************************************
//* 
//* Public functions
//*
//*************************************************************


//! Discover Characteristics when connected
/**
 *  This function is called by the SensorBox class when it is connecting to the 
 *  SensorBox.
 *  This overrites the standard implementation and request characteristics 
 *  discovery 
 *  
 *  @returns TRUE   
*/       
- (BOOL) firstDiscover
{
    [self discover];
    return TRUE;
}

//! Request value for serial number
/**
 *  Requests read for serial number. Once the value is updated a 
 *  callback will be invoked.
 *  Upon completion (callback) the value can be read using getSerialNumber 
 *
 *  @returns FALSE if the characteristic is not found
*/       
- (BOOL) readSerialNumber
{
    return [self readWithUUIDString:UUID_SERIALNUMBER];
}

//! Returns Serial Number
/**
 *  Before calling this function, readSerialNumber must be called and its 
 *  completion must be reported on the delegate.
 *  This function returns the last read value.
 *  
 *  @returns NSString with Serial Number
*/     
- (NSString*) getSerialNumber
{
    NSData* data = [self getDataWithUUIDString:UUID_SERIALNUMBER];
        
    NSString* str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    return str;
}

//! Request value for serial ID
/**
 *  Requests read for serial ID. Once the value is updated a 
 *  callback will be invoked.
 *  Upon completion (callback) the value can be read using getSystemIdString 
 *
 *  @returns FALSE if the characteristic is not found
*/       
- (BOOL) readSystemID
{
    return [self readWithUUIDString:UUID_SYSTEMID];
}

//! Returns SystemID
/**
 *  Before calling this function, readSystemID must be called and its 
 *  completion must be reported on the delegate.
 *  This function returns the last read value.
 *  
 *  @returns NSString with System ID
*/     
- (NSString*) getSystemIdString
{
    NSData* data = [self getDataWithUUIDString:UUID_SYSTEMID];
    
    char buffer[8];
    [data getBytes:buffer length:8];
    
    NSString* str = [[[NSString alloc] initWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X", buffer[7]&0xff, buffer[6]&0xff, buffer[5]&0xff, buffer[4]&0xff, buffer[3]&0xff, buffer[2]&0xff, buffer[1]&0xff, buffer[0]&0xff] autorelease];
    return str;
}

//! Request value for FirmwareVersion
/**
 *  Requests read for firmware version. Once the value is updated a
 *  callback will be invoked.
 *  Upon completion (callback) the value can be read using getSystemIdString
 *
 *  @returns FALSE if the characteristic is not found
 */
- (BOOL) readFirmwareVersion
{
    return [self readWithUUIDString:UUID_FIRMWAREVERSION];
}

//! Returns FirmwareVersion
/**
 *  Before calling this function, readFirmwareVersion must be called and its
 *  completion must be reported on the delegate.
 *  This function returns the last read value.
 *
 *  @returns NSString with System ID
 */
- (NSString*) getFirmwareVersion
{
    NSData* data = [self getDataWithUUIDString:UUID_FIRMWAREVERSION];
    
    NSString* str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    return str;
}

//! Request value for HardwareVersion
/**
 *  Requests read for hardware version. Once the value is updated a
 *  callback will be invoked.
 *  Upon completion (callback) the value can be read using getSystemIdString
 *
 *  @returns FALSE if the characteristic is not found
 */
- (BOOL) readHardwareVersion
{
    return [self readWithUUIDString:UUID_HARDWAREVERSION];
}

//! Returns HardwareVersion
/**
 *  Before calling this function, readHardwareVersion must be called and its
 *  completion must be reported on the delegate.
 *  This function returns the last read value.
 *
 *  @returns NSString with System ID
 */
- (NSString*) getHardwareVersion
{
    NSData* data = [self getDataWithUUIDString:UUID_HARDWAREVERSION];
    
    NSString* str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    return str;
}

@end
