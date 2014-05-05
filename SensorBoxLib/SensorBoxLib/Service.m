//
//  Service.m
//  SensorBoxLib
//
//  Created by Aimago/man 
//  Copyright (c) 2012 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  26.04.2012   man    First Release
//  06.06.2012   man    Finalize & Documentation
//  07.11.2013   man    Update for compatibilty
//  24.12.2013   man    Improved debug output handling
//  13.03.2014   man    Implemented suggested changes by Hardwig


#import "Service.h"
#import "UUIDHelper.h"
#import "DebugManager.h"

@implementation Service

@synthesize cbService;
@synthesize sensorBox;
@synthesize cbCharacteristics;
@synthesize delegate;

//*************************************************************
//* 
//* Public functions
//*
//*************************************************************


//! Initialize with service
/**
 *  Initialize the object with a CBService and SensorBox reference
 *  
 *  @param inCBService CBService linked to this service
 *  @param inSensorBox SensorBox for this service
 *  
 *  @returns Initialized object      
*/ 
- (id) initWithCBService: (CBService*)inCBService
            sensorBox:(SensorBox*)inSensorBox
{
    self = [super init];
    
    if ( self ) 
    {
        self->finishedInit = FALSE;
        self.cbService = inCBService;
        self.sensorBox = inSensorBox;
        cbCharacteristics = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) dealloc
{
    self.cbService = nil;
    self.cbCharacteristics = nil;
    [super dealloc];
}

//! Discover Characteristics when connected
/**
 *  This function is called by the SensorBox class when it is connecting to the 
 *  SensorBox.
 *  This implementation is the default implementation, where we don't look for
 *  characteristics. This will be overritten by derived classes which should 
 *  discover Characteristics
 *  
 *  @returns TRUE if discover was initiated.  
*/       
- (BOOL) firstDiscover
{
    // By default we don't discover characteristics
    self->finishedInit = TRUE;
    return FALSE;
}

//! Discover Characteristics
/**
 *  Initiates discovery for characteristics. The result will be reported to the SensorBox
 *  which will forward it to us.
*/  
- (void) discover
{
    [self.sensorBox.peripheral discoverCharacteristics:nil forService:self.cbService];
}

//! Reports completion of discovery for characteristics
/**
 *  This function is called by SensorBox upon received callback from CBCentralManager
 *  on completion of characteristics discovery
*/ 
- (void) setFinishDiscover
{
    self->finishedDiscover = TRUE;
    self->finishedInit = TRUE;
    
    [DebugManager writeDebugLogWithLevel:DebugLevelVerbose messsage:@"Found characteristics for %s", [[UUIDHelper CBUUIDToString:self.cbService.UUID] cStringUsingEncoding:NSASCIIStringEncoding]];
    for(int j=0; j<self.cbService.characteristics.count; j++) {
        CBCharacteristic *c = [self.cbService.characteristics objectAtIndex:j];
        NSString* uuid = [UUIDHelper CBUUIDToString:c.UUID];
        
        [self.cbCharacteristics setObject:c forKey:uuid];
        [DebugManager writeDebugLogWithLevel:DebugLevelVerbose messsage:@"%@",uuid];
    }
}

//! Returns if discovery completed
/**
 *  This function returns TRUE if the discovery for characteristics has completed.
 *  @returns TRUE if discovery completed
*/  
- (BOOL) didFinishDiscover
{
    return self->finishedDiscover;
}

//! Returns if the service is initialized
/**
 *  This function returns TRUE if the service is happy on its initialization state.
 *  This differs from didFinishDiscover such that this function immediately returns TRUE
 *  if the service doesn't want to discover characteristics upon connection. It
 *  returns FALSE if the service needs characteristic discovery and this hasn't completed yet.
 *  
 *  @returns TRUE if the service has finished initializing
*/          
- (BOOL) didFinishInit
{
    return self->finishedInit;
}

//! Request value for a characteristic identified with UUID string
/**
 *  Requests read for a characteristic. Once the value is updated a 
 *  callback will be invoked.
 *  The UUID must be formated the same way it is formated when 
 *  converted from CBUUID to string.
 *  Example (128-bit): <aba27100 143b4b81 a444edcd 0000f022>
 *  Example (16-bit): <2a25>   
 *  
 *  @param uuid UUID to read. See remarks.
 *  @returns FALSE if the characteristic is not found
*/       
- (BOOL) readWithUUIDString:(NSString *)uuid
{
    CBCharacteristic *c = [self.cbCharacteristics objectForKey:uuid];
    if ( ! c ) return FALSE;
    
    [self.sensorBox.peripheral readValueForCharacteristic:c];
    return TRUE;
}

//! Writes value for a characteristic identified with UUID string
/**
 *  Requests write for a characteristic. No response is requested for the
 *  write completion. 
 *  The UUID must be formated the same way it is formated when 
 *  converted from CBUUID to string.
 *  Example (128-bit): <aba27100 143b4b81 a444edcd 0000f022>
 *  Example (16-bit): <2a25>   
 *  
 *  @param uuid UUID to write. See remarks.
 *  @param inData Data to write 
 *  @returns FALSE if the characteristic is not found
*/       
- (BOOL) writeWithUUIDString:(NSString *)uuid data:(NSData*)inData
{
    CBCharacteristic *c = [self.cbCharacteristics objectForKey:uuid];
    if ( !c ) return FALSE;
    
    [self.sensorBox.peripheral writeValue:inData forCharacteristic:c type:CBCharacteristicWriteWithResponse];
    
    return TRUE;
}

//! Gets value for a characteristic identified with UUID string
/**
 *  Returns the value for a characteristic. The value must first have been
 *  read with readWithUUIDString and reported successful by the callback.
 *  The UUID must be formated the same way it is formated when 
 *  converted from CBUUID to string.
 *  Example (128-bit): <aba27100 143b4b81 a444edcd 0000f022>
 *  Example (16-bit): <2a25>
 *  
 *  @param uuid UUID to get value. See remarks.
 *  @returns nil if characteristic is not found, otherwise NSData with data
*/       
- (NSData*) getDataWithUUIDString:(NSString *)uuid
{
    CBCharacteristic *c = [self.cbCharacteristics objectForKey:uuid];
    if ( ! c ) return nil;
    return c.value;
}

//! Reports update of value
/**
 *  This function is called by SensorBox upon received delegate that
 *  value has been updated.
 *  The function delegates the update to our delegate. 
 *  Do not call this function directly.
 *  
 *  @param characteristic Characteristic with updated value.
**/     
- (void) setValueUpdated:(CBCharacteristic *)characteristic
{
    NSString* uuid = [UUIDHelper CBUUIDToString:characteristic.UUID];
	
	if ([[self delegate] respondsToSelector:@selector(sensorBox:valueUpdated:characteristicUUID:)])
    [[self delegate] sensorBox:[self sensorBox] valueUpdated:self characteristicUUID:uuid];
}

//! Reports update of value error
/**
 * This function is called by SensorBox upon error on update of a
 * value.
 * @param error Error received
 * @param characteristic Related characteristic
**/
- (BOOL) setValueUpdateError:(NSError*)error forCharacteristic:(CBCharacteristic*)characteristic
{
    // Do nothing in the standard case
    return false;
}

//! Enables or disables notify on specific characteristic
/**
 *  Enables or disables notifiy on a specific characteristic
 *  The UUID must be formated the same way it is formated when
 *  converted from CBUUID to string.
 *  Example (128-bit): <aba27100 143b4b81 a444edcd 0000f022>
 *  Example (16-bit): <2a25>
 *
 *  @param uuid UUID to write. See remarks.
 *  @param enable TRUE if notify should be enabled
 *  @returns FALSE if the characteristic is not found
 */
- (BOOL) setNotifyWithUUIDString:(NSString *)uuid enableNotify:(Boolean)enable
{
    CBCharacteristic *c = [self.cbCharacteristics objectForKey:uuid];
    if ( !c ) return FALSE;
    
    [self.sensorBox.peripheral setNotifyValue:enable forCharacteristic:c];
    
    return TRUE;
}

@end
