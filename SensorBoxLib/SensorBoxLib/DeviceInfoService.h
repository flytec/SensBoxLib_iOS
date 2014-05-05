//
//  DeviceInfoService.h
//  SensorBoxLib
//
//  Created by Aimago/man 
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  26.4.2012   man    First Release
//  06.6.2012   man    Finalize & Documentation


#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "Service.h"

//! Service class for DeviceInfo service
/** 
 *  DeviceInfo is a mandatory service to be implemented by all BLE peripherals.
 *  It can be used to read device information such as Serial number.
*/  
@interface DeviceInfoService : Service

//! UUID for Serial Number characteristic
#define UUID_SERIALNUMBER @"<2a25>"
//! UUID for SystemID characteristic
#define UUID_SYSTEMID     @"<2a23>"
//! UUID for FirmwareVersion characteristic
#define UUID_FIRMWAREVERSION @"<2a26>"
//! UUID for HardwareVersion charactersitic
#define UUID_HARDWAREVERSION @"<2a27>"
//! UUID for this service
#define UUID_DEVICEINFOSERVICE @"<180a>"


- (BOOL) readSerialNumber;
- (NSString*) getSerialNumber;

- (BOOL) readSystemID;
- (NSString*) getSystemIdString;

- (BOOL) readFirmwareVersion;
- (NSString*) getFirmwareVersion;

- (BOOL) readHardwareVersion;
- (NSString*) getHardwareVersion;

@end
