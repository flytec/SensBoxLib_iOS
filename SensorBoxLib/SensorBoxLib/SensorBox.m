//
//  SensorBox.m
//  SensorBoxLib
//
//  Created by Aimago/man 
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  26.04.2012   man    First Release
//  06.06.2012   man    Finalize & Documentation
//  07.11.2013   man    Implemented file transfer and some more error handling
//  24.12.2013   man    Improved debug output handling, improved delegate handling
//  13.03.2014   man    Implemented suggested changes by Hardwig
//  28.04.2014   man    Fixed issue in dealloc (by Hardwig)
                                      
#import "SensorBox.h"
#import "UUIDHelper.h"
#import "Service.h"
#import "DeviceInfoService.h"
#import "SensorService.h"
#import "CommunicationService.h"
#import "CommMessageEvent.h"
#import "FileTransferHelper.h"
#import "DebugManager.h"


@implementation SensorBox

@synthesize peripheral;
@synthesize CM;
@synthesize delegate;
@synthesize services;
@synthesize deviceInfoService;
@synthesize sensorService;
@synthesize communicationService;
@synthesize isConnected;
@synthesize isDiscovered;
@synthesize serialNumber;
@synthesize deviceName;
@synthesize fileTransferHelper;

//*************************************************************
//* 
//* Private Functions first
//* 
//*************************************************************

//! Will be called on dispose of the object
-(void) dealloc
{
 // all attributes that have an assignment signature and that may be referenced during the deallocation
 // process have to be set to nil explicitely, otherwise crashes will occur
	[self setDelegate:nil];
	[[self fileTransferHelper] setCommService:nil];
	[[self peripheral] setDelegate:nil];

    self.peripheral = nil;
    self.CM = nil;
    self.services = nil;
    self.deviceName = nil;
    self.fileTransferHelper = nil;

	[super dealloc];
}

//! Parses the serial number from the device name
/** 
    SensorBoxes report their serialnumber as part of the device name. This function
    parses the right part of the device name and looks for a number. The number
    is stored in the serialnumber property field. The serial number is 0 if the 
    parsing failed.
  
    @param inDeviceName Devicename advertised by the SensorBox
*/
- (void) parseName:(NSString*)inDeviceName
{
    [DebugManager writeDebugLogWithLevel:DebugLevelVerbose messsage:@"Device Name %@", inDeviceName];
    
    self.deviceName = inDeviceName;
    self.serialNumber = 0;
    
    int pos = inDeviceName.length - 1;
    unichar c; 
    while ( pos >= 0 )
    {
        [inDeviceName getCharacters:&c range:NSMakeRange(pos, 1)];
        if ( c < '0' || c > '9' ) break; 
        pos--;
    }
    if ( pos < inDeviceName.length - 1 )
    {
        pos++;
        NSString* serial = [inDeviceName substringFromIndex:pos];
        self.serialNumber = [serial intValue];
    }
}



//*************************************************************
//* 
//* Callback from CBPeripheralDelegate. Private functions.
//*
//*************************************************************


//! Invoked when the peripheral discovered a new service
/** 
    This function is invoked when discoverServices completed
    If error is nil the discovery was successful.
    We create a Service object for each service. Known services are directly
    referenced with their pointer.
    Initiate a discover of characteristics on all known services
    
    @param error Reported error if the discoverServices failed.
*/     
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error;
{
    self.deviceInfoService = nil;
    self.sensorService = nil;
    self.communicationService = nil;
    
    if ( error == nil )
    {
        [DebugManager writeDebugLogWithLevel:DebugLevelVerbose messsage:@"Found services: "];
        
        for(int i=0; i<self.peripheral.services.count; i++)
        {
            CBService *cbservice = [self.peripheral.services objectAtIndex:i];
            NSString *uuid = [UUIDHelper CBUUIDToString:cbservice.UUID];
            Service* service = nil;
            
            [DebugManager writeDebugLogWithLevel:DebugLevelVerbose messsage:@"%@", uuid];
                        
            if ( [uuid isEqualToString:UUID_DEVICEINFOSERVICE ] ) // Device Info
            {
                service = [[DeviceInfoService alloc] initWithCBService:cbservice sensorBox:self];
                self.deviceInfoService = (DeviceInfoService*)service;
                [service firstDiscover];
            }
            else if ( [uuid isEqualToString:UUID_SENSORSERVICE ] )
            {
                service = [[SensorService alloc] initWithCBService:cbservice sensorBox:self];
                self.sensorService = (SensorService*)service;
                [service firstDiscover];
            }
            else if ( [uuid isEqualToString:UUID_COMMSERVICE ] ) 
            {
                service = [[CommunicationService alloc] initWithCBService:cbservice sensorBox:self];
                self.communicationService = (CommunicationService*)service;
                [service firstDiscover];
                FileTransferHelper* fhelper = [[[FileTransferHelper alloc] initWithCommunicationService:(CommunicationService*)service] autorelease];
                self.fileTransferHelper = fhelper;
            }
            else
            {
                service = [[Service alloc] initWithCBService:cbservice sensorBox:self];
                [service firstDiscover];
            }
            
            [self.services setValue:service forKey:uuid];
            [service release];
        }
        [DebugManager writeDebugLogWithLevel:DebugLevelVerbose messsage:@"\r\n"];
    }
    else 
    {
        [DebugManager writeDebugLogWithLevel:DebugLevelErrors messsage:@"Error discovering service %@\r\n", error.description];
        [self.services removeAllObjects]; 
    }
}

//! Invoked when the peripheral discovered new characteristics
/**
 *
 *  Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 *  If successful, "error" is nil and discovered characteristics, if any, have been merged into the
 *  "characteristics" property of the service. In that case we update the service and tell him the 
 *  discovery has finished.
 *  If all services finished discovery we declare ourselfs connected.  
 *  If unsuccessful, "error" is set with the encountered failure and logged.
 *  
 *  @param service CBService which discovered characteristics
 *  @param error   Error message if discover failed.   
*/
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ( error == nil )
    {
        BOOL finished = TRUE;
        
        NSString *uuid = [UUIDHelper CBUUIDToString:service.UUID];
        Service* s = [self.services objectForKey:uuid];
        
        if ( s )
        {
            [s setFinishDiscover];
        }
        
        for ( Service* value in [self.services allValues] )
        {
            if ( ! [value didFinishInit] ) finished = FALSE;
        }
        
        if ( finished )
        {
            self.isConnected = TRUE;
            if ([[self delegate] respondsToSelector:@selector(sensorBox:connectStateChanged:)])
							[self.delegate sensorBox:self connectStateChanged:TRUE];
        }
    }
    else 
    {
        [DebugManager writeDebugLogWithLevel:DebugLevelErrors messsage:@"Error discovering characteristics %@\r\n", error.description];
    }
}

//! Invoked when value for a characteristic has updated. 
/**
 *  Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
 *  If unsuccessful, "error" is set with the encountered failure and logged.
 *  If successful the corresponding service is looked up and updated with the value. The service then delegates the update to the
 *  callee.
 *     
 *  @param characteristic which updated the value
 *  @param error if the update failed. 
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSString *uuid = [UUIDHelper CBUUIDToString:characteristic.service.UUID];
    Service* s = [self.services objectForKey:uuid];

    if ( error == nil ) 
    {
        if ( s )
        {
            [s setValueUpdated:characteristic];
        }
    }
    else 
    {
        if ( s )
        {
            if ( ! [s setValueUpdateError:error forCharacteristic:characteristic] )
            {
                [DebugManager writeDebugLogWithLevel:DebugLevelErrors messsage:@"Error updating value %@\r\n", error.description];
            }
        }
        else
        {
            [DebugManager writeDebugLogWithLevel:DebugLevelErrors messsage:@"Error updating value %@\r\n", error.description];
        }
    }
}

//! Invoked when value for a characteristic has been written
/**
 * Invoked upon completion of a -[writeValueForCharacteristic:] request.
 * If unsuccessful the error is written to log
 *
 *  @param peripheral Peripheral which was updated 
 *  @param characteristic which was written
 *  @param error if the update failed. 
 */    
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if ( error != nil )
    {
        [DebugManager writeDebugLogWithLevel:DebugLevelErrors messsage:@"Error writing value %@\r\n", error.description];
    }
}



//! Invoked when RSSI read completed
/**
 *  Invoked upon compleation of RSSI Read.
 *  If successful error is nil. In that case we report the update to our delegate. 
 *  If unsuccessful we log the error. 
 *  It was observed that readRSSI occasionaly fails with "operation not completed". 
 *  Currently it is suggested to use a timer to read the RSSI in regular interval.
 *
 *  @param inPeripheral peripheral which reports the updated RSSI (must be our peripheral)
 *  @param error if the update failed.
 */              
- (void) peripheralDidUpdateRSSI:(CBPeripheral *)inPeripheral error:(NSError *)error
{
    if ( error == nil ) 
    {
        if ([[self delegate] respondsToSelector:@selector(sensorBox:rssiReadCompleted:)])
					[[self delegate] sensorBox:self rssiReadCompleted:inPeripheral.RSSI];
    }
    else 
    {
        //[self.peripheral readRSSI]; // Retry
        [DebugManager writeDebugLogWithLevel:DebugLevelVerbose messsage:@"Error reading RSSI %@\r\n", error.description];
    }
}

//! Invoked when notify change is completed
/**
 * Invoked upon completion of notify change.
 * This function is only used to check for error and to log the error
 *
 * @param peripheral peripheral affected
 * @param characteristic characetristic affected
 * @param error Error occured. nil if operation was successful
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if ( error != nil )
    {
        [DebugManager writeDebugLogWithLevel:DebugLevelErrors messsage:@"Error setting notify for %@, error %@", [UUIDHelper CBUUIDToString:characteristic.UUID], error.description];
    }
}





//*************************************************************
//* 
//* Public functions
//*
//*************************************************************

//! Basic init
/** 
 *  This is the base init. It should not be called directly. Instead
 *  use initWithPeripheral.
 *  
 *  @returns Initialized object
*/     
- (id) init
{
    self = [super init];
    if ( self )
    {
        services = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}


//! Init with peripheral and CBCentralManager
/** 
 *  This is the normally used init function. It is called by SensorBoxLib when 
 *  a new SensorBox is discovered.
 *  
 *  @param inPeripheral CBPeripheral for that SensorBox
 *  @param inCM reference to CBCentralManager instance
 *  
 *  @returns Initialized object  
*/       
- (id) initWithPeripheral:(CBPeripheral*)inPeripheral
           centralManager:(CBCentralManager*)inCM
{
    self = [self init];
    
    if ( self ) 
    {
        self.peripheral = inPeripheral;
        self.isDiscovered = TRUE;
        [self.peripheral setDelegate:self];
        [self parseName:self.peripheral.name];
        self.CM = inCM;
    }
    return self;
}

//! returns the UUID for the current peripheral
/** 
 *  At this time it is unclear how the UUID is linked with the bluetooth
 *  MAC Address. It is suggested not to use this UUID.
 *  
 *  @returns UUID of peripheral
*/    
- (CFUUIDRef) getUUID
{
    return (CFUUIDRef)self.peripheral.UUID;
}

//! Connects to the SensorBox
/**
 *  This function should be called to connect to the SensorBox. The function
 *  automatically connects and discovers services.
 *  The sensorBoxConnectStateChanged callback will be invoked when the connection
 *  is successful.  
 *  The function returns without action if the SensorBox is already connected.    
*/  
- (void) connect
{
    // Return if we are already connected
    if ( self.isConnected ) return;
  
    [self.CM connectPeripheral:self.peripheral options:nil];
}

//! Disconnects the SensorBox
/**
 *  This function disconnects a existing SensorBox connected.
 *  The sensorBoxConnectStateChanged callback will be invoked once the connection
 *  is terminated.   
*/ 
- (void) disconnect
{
    CommunicationService* s1 = self.communicationService;
    CommMessageEvent* msg = [[CommMessageEvent alloc] initWithEventCode:COMMMESSAGE_EVENT_DISCONNECT expectResponse:false];
    [s1 sendMessage:msg];
    [msg release];
    
    [self.CM cancelPeripheralConnection:self.peripheral];
}


//! Updates connection state
/** 
 *  This function is called by the SensorBoxLib to update the connection state
 *  of the SensorBox when a change is reported by the CBCentralmanager.
 *  The function should NEVER be called by another entity
 *
 *  @param connected TRUE if the CBCentralManager reports connected state
*/     
- (void) reportConnectStateChanged:(BOOL)connected
{
    if ( connected ) 
    {
        // This will report the state further
        [self.peripheral discoverServices:nil];
    }
    else 
    {
        self.isConnected = FALSE;
        if ([[self delegate] respondsToSelector:@selector(sensorBox:connectStateChanged:)])
					[[self delegate] sensorBox:self connectStateChanged:NO];
    }
}

//! Read request for RSSI
/**
 *  Requests a RSSI value read from the peripheral.
 *  The sensorBoxRSSIReadCompleted callback will be invoke once the read finished
 *  It was observed that some read requests fail. In those cases the callback will
 *  not be invoked. It is suggested not to rely on the invoke of sensorBoxRSSIReadCompleted.
*/    
- (void) readRSSI
{
    [self.peripheral readRSSI];
}


@end
