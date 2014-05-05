//
//  SensorBox.h
//  SensorBoxLib
//
//  Created by Aimago/man 
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  26.04.2012   man    First Release
//  06.06.2012   man    Finalize & Documentation
//  07.11.2013   man    Added file transfer helper
//  24.12.2013   man    Improved debug output handling
//  13.03.2014   man    Implemented suggested changes by Hardwig

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class SensorBox;

//! Delegate for SensorBox update callbacks
/**
    This delegate is used to update the state of a SensorBox to the callee
*/
@protocol SensorBoxDelegate <NSObject>
@optional
//! Reports a connection state change
/**
    This function is invoked when a connection to a SensorBox has completed or 
    if the connection to the SensorBox is lost
    
 		@param sensorBox SensorBox whose state has changed.
    @param connected TRUE if the connection exists and FALSE if the connection is terminated
*/
-(void) sensorBox:(SensorBox*)sensorBox connectStateChanged:(BOOL)connected;

//! Invoked when RSSI read completed
/**
    This function is invoked after readRSSI when the value has been updated
    
    @param sensorBox SensorBox whose RSSI read has been completed.
    @param RSSI new RSSI value in dB.
**/
-(void) sensorBox:(SensorBox*)sensorBox rssiReadCompleted:(NSNumber*)RSSI;

@required

@end


//! Object of a SensorBox
/** 
    This class represents a SensorBox and is the main interface to operate with
    a sensorbox.
*/
@interface SensorBox : NSObject<CBPeripheralDelegate>

//! CBPeripheral object linkted to that sensorbox
@property(retain, nonatomic) CBPeripheral* peripheral;

//! CBCentralManager instance to be used
@property(retain, nonatomic) CBCentralManager* CM;

//! Delegate to report state change to 
@property(assign, nonatomic) id <SensorBoxDelegate> delegate;

//! List of all services connected with that SensorBox
@property(retain, nonatomic) NSMutableDictionary* services;

//! Instance of DeviceInfoService 
@property(assign, nonatomic) id deviceInfoService;

//! Instance of SensorService 
@property(assign, nonatomic) id sensorService;

//! Instance of CommunicationService
@property(assign, nonatomic) id communicationService;

//! Instance of FileTransferHelper
@property(retain, nonatomic) id fileTransferHelper;

//! Serialnumber of sensorbox. This is a numeric value from 1..65535
@property(nonatomic) int serialNumber;

//! Devicename of the SensorBox
/**
    The device name contains the serialnumber
*/
@property(retain, nonatomic) NSString* deviceName;

//! Current connection state
@property(nonatomic) BOOL isConnected;

//! Discovey state
/**
 TRUE if discovery of services has completed
 */
@property(nonatomic) BOOL isDiscovered;

// Public functions are documented in the .m file
- (id) initWithPeripheral:(CBPeripheral*)inPeripheral
           centralManager:(CBCentralManager*)inCM;

- (CFUUIDRef) getUUID;
- (void) connect;
- (void) reportConnectStateChanged:(BOOL)connected;
- (void) disconnect;
- (void) readRSSI;

@end
