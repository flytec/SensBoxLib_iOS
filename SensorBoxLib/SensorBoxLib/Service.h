//
//  Servie.m
//  SensorBoxLib
//
//  Created by Aimago/man 
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  26.04.2012   man    First Release
//  06.06.2012   man    Finalize & Documentation
//  07.11.2013   man    Minor modifications for error handling
//  24.12.2013   man    Improved debug output handling
//  13.03.2014   man    Implemented suggested changes by Hardwig

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "SensorBox.h"

// Predeclare here. Real declaration is at the end of the document.
@protocol ServiceDelegate;

//! Abstract class for Service
/**
 *  This is a abstract class implementation for a SensorBox service. The 
 *  real services will be implemented as derivates and overwrite some
 *  functions.
*/   
@interface Service : NSObject {
    @protected
    BOOL finishedDiscover;
    BOOL finishedInit;
}

//! CBService linked to this Service
@property(retain,nonatomic) CBService* cbService;

//! SensorBox linked to this Service
@property(assign,nonatomic) SensorBox* sensorBox;

//! List of Characteristics (CBCharachteristics) linked to that service
@property(retain,nonatomic) NSMutableDictionary* cbCharacteristics;

//! Delegate to report service updates to
@property(nonatomic,assign) id <ServiceDelegate> delegate;


- (id) initWithCBService: (CBService*)inCBService
            sensorBox: (SensorBox*)inSensorBox;

- (BOOL) firstDiscover;
- (void) discover;
- (void) setFinishDiscover;
- (BOOL) didFinishDiscover;
- (BOOL) didFinishInit;


- (BOOL) readWithUUIDString:(NSString*) uuid;
- (NSData*) getDataWithUUIDString:(NSString *)uuid;
- (void) setValueUpdated:(CBCharacteristic *)characteristic;
- (BOOL) setValueUpdateError:(NSError*)error forCharacteristic:(CBCharacteristic*)characteristic;
- (BOOL) writeWithUUIDString:(NSString *)uuid data:(NSData*)inData;
- (BOOL) setNotifyWithUUIDString:(NSString *)uuid enableNotify:(Boolean)enable;

@end

//! Delegate for service update callbacks
/**
 *  This delegate protocol is used to report changes from a Service in a SensorBox
*/ 
@protocol ServiceDelegate <NSObject>
@optional

//! Reports an updated value
/**
 *  This function is invoked upon completion of a value read.
 *  
 *  @param service Service object which was updated
 *  @param uuid UUID as NSString for the characteristic which was updated
**/    
-(void) sensorBox:(SensorBox*)sensorBox valueUpdated:(Service*)service characteristicUUID:(NSString*) uuid;
@required
@end
