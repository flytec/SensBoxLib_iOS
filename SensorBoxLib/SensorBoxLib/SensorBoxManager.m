//
//  SensorBoxManager.m
//  SensorBoxManager.m
//
//  Created by Aimago/man 
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  26.04.2012   man    First Release
//  06.06.2012   man    Finalize & Documentation
//  07.11.2013   man    Some more debug output
//  24.12.2013   man    Renamed to SensorBoxManager, changed to singleton, improved debug outputs
//  13.03.2014   man    Implemented suggested changes by Hardwig

#import "SensorBoxManager.h"
#import "UUIDHelper.h"
#import "DebugManager.h"
#import "SensorBoxErrors.h"
#import "SensorBox.h"
#import "DeviceInfoService.h"
#import "SensorService.h"
#import "CommunicationService.h"
#import "CommMessage.h"
#import "CommMessageEvent.h"
#import "CommMessageSettings.h"
#import "CommMessageFile.h"
#import "FileTransferHelper.h"

@implementation SensorBoxManager

@synthesize delegate;
@synthesize CM;
@synthesize sensorBoxes;


//*************************************************************
//*
//* Singleton implementation
//*
//*************************************************************

static SensorBoxManager *managerInstance = nil;


//! Gets the shared instance and create it if necessary
/**
 * This function shoould be used to access the singleton object. The function automatically creates
 * the object if it doesn't exist before
 */
+ (SensorBoxManager *)managerInstance {
    if ( managerInstance == nil ) {
        managerInstance = [[super allocWithZone:NULL] init];
    }
    
    return managerInstance;
}

//! Init method which is called internally by the singleton initialization
- (id) init
{
    self = [super init];
    
    if ( self ) {
        self.CM = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    
    return self;
}

// dealloc method will never be called, as the singleton survives for the singleton survives for the duration of the app
// Implement it anyway
-(void) dealloc
{
    // This will never be called
    [self.CM setDelegate:nil];
    self.CM = nil;
    self.sensorBoxes = nil;
    [super dealloc];
}

// We don't want to allocate a new instance, so return the current one
+ (id)allocWithZone:(NSZone*)zone {
    return [[self managerInstance] retain];
}

// Equally we don't want to generate multipe copies
- (id)copyWithZone:(NSZone *)zone {
    return self;
}

// Do nothing, we don't have a retain counter
- (id) retain {
    return self;
}

// Replace the retain counter so we can never release this object
- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

// This function is empty, we don't want to let the user release this object
- (oneway void) release {
    
}

// Do nothing
- (id) autorelease {
    return self;
}



//*************************************************************
//* 
//* Private Functions first
//* 
//*************************************************************

//! Converts ManagerState into readable format
/** 
    centralManagerStateToString prints information text about a given CBCentralManager state

    @param state State to print info of
    
    @param String with english textual representation of the bluetooth state
 */
- (const char *) centralManagerStateToString: (int)state{
    switch(state) {
        case CBCentralManagerStateUnknown: 
            return "State unknown (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateResetting:
            return "State resetting (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateUnsupported:
            return "State BLE unsupported (CBCentralManagerStateResetting)";
        case CBCentralManagerStateUnauthorized:
            return "State unauthorized (CBCentralManagerStateUnauthorized)";
        case CBCentralManagerStatePoweredOff:
            return "State BLE powered off (CBCentralManagerStatePoweredOff)";
        case CBCentralManagerStatePoweredOn:
            return "State powered up and ready (CBCentralManagerStatePoweredOn)";
        default:
            return "State unknown";
    }
    return "Unknown state";
}

//! Timer callback. Will be called when scan times out.
/**
    scanTimer is called when findBLEPeripherals has timed out, it stops the CentralManager from scanning further and prints out information about known peripherals
    
    @param timer Backpointer to timer
*/
- (void) scanTimer:(NSTimer *)timer {
    [self.CM stopScan];
    
    [DebugManager writeDebugLogWithLevel:DebugLevelInfo messsage:@"Scanning finished\r\n"];
    
    
    // If we sensorBoxes array is not null, check if we need to remove any missing sensorbox
    if ( self.sensorBoxes ) 
    {
        NSMutableArray* copy = [[[NSMutableArray alloc] initWithArray:self.sensorBoxes copyItems:FALSE] autorelease];
        for(int i=0; i<copy.count; i++)
        {
            SensorBox *sb = [copy objectAtIndex:i];
            if ( ! sb.isDiscovered )
            {
                NSString* string = [UUIDHelper UUIDToString:[sb getUUID]];
                [DebugManager writeDebugLogWithLevel:DebugLevelInfo messsage:@"Device with UUID %@ is lost. Removing from list\r\n", string];
                [self.sensorBoxes removeObject:sb];
            }
        }
    }
    
    // Send notice to delegate
	if ([[self delegate] respondsToSelector:@selector(sensorBoxListUpdated:)])
    [self.delegate sensorBoxListUpdated:TRUE];
}




//*************************************************************
//* 
//* Callback from CBCentralManagerDelegate. Private functions.
//*
//*************************************************************

//! Invoked when CBCentralManager state changed
/*
    This function is called by the CBCentralManager when the bluetooth state changes.
    We forward this message to our own delegates.
    
    @param central CBCentralManager instance
*/
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    [DebugManager writeDebugLogWithLevel:DebugLevelInfo messsage:@"Status of CBCentralManager changed %s\r\n",[self centralManagerStateToString:central.state]];
    
    if ([[self delegate] respondsToSelector:@selector(bluetoothStateChanged:)])
      [self.delegate bluetoothStateChanged:(central.state == CBCentralManagerStatePoweredOn)];
}

//! Invoked when a new peripheral is discovered
/**
    This function gets called during scan when a new peripheral is found. We check if we alrady have this
    SensorBox. If yes, the finding gets ignored. Otherwise it is added to the list of SensorBoxes.
    In the end our own delegate is called.
    Scan makes sure, that only SensorBoxes are found. (it filters with specific service UUID)
    
    @param central CBCentralManager instance
    @param peripheral Instance of found peripheral
    @param advertisementData Advertisement information of peripheral
    @param RSSI RSSI level
*/  
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
  
    NSString* string = peripheral.uuidString;
    [DebugManager writeDebugLogWithLevel:DebugLevelInfo messsage:@"found device with UUID %@\r\n", string];
    
    if(!self.sensorBoxes)
    {
        sensorBoxes = [[NSMutableArray alloc] initWithObjects:[[[SensorBox alloc] initWithPeripheral:peripheral centralManager:self.CM] autorelease],nil];
    }
    else
    {
        // Check if this is a duplicate
        for(int i=0; i<self.sensorBoxes.count; i++)
        {
            SensorBox *sb = [self.sensorBoxes objectAtIndex:i];
            if ( [sb.peripheral uuidIsEqual:peripheral]) {
                // This is a duplicate discover or we already discovered it earlier
                sb.isDiscovered = TRUE;
                if ([[self delegate] respondsToSelector:@selector(sensorBoxListUpdated:)])
									[self.delegate sensorBoxListUpdated:FALSE];
                
                return;
            }
        }
        // No duplicate. Create SensorBox object
        [self.sensorBoxes addObject:[[[SensorBox alloc] initWithPeripheral:peripheral centralManager:self.CM] autorelease]];
    }
    
    // Report SensorBox update to parent
    if ([[self delegate] respondsToSelector:@selector(sensorBoxListUpdated:)])
			[self.delegate sensorBoxListUpdated:FALSE];
}

//! Invoked when connection to peripheral succeeded
/**
    This function gets called from CBCentralManager when a connection to a peripheral succeeded.
    We lookup the peripheral in our SensorBox list and if found we report the connection state
    to the SensorBox object.
    
    @param central CBCentralManager instance
    @param peripheral Instance of connected peripheral
*/
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    // Find SensorBox object for that peripheral
    if ( self.sensorBoxes ) 
    {
        [DebugManager writeDebugLogWithLevel:DebugLevelInfo messsage:@"Connect Peripheral: %@\r\n", peripheral.uuidString];
        
        for(int i=0; i<self.sensorBoxes.count; i++)
        {
            SensorBox *sb = [self.sensorBoxes objectAtIndex:i];
            
            if ([sb.peripheral uuidIsEqual:peripheral]) {
                // Sensorbox found. Report the state change to the SensorBox object.
                [sb reportConnectStateChanged:TRUE];
                return;
            }
        }
    }
}

//! Invoked whenever an existing connection with the peripheral has been teared down
/**
    This function gets called from CBCentralManager when a connection to a peripheral is 
    terminated.
    We lookup the peripheral in our SensorBox list and if found we report the connection state
    to the SensorBox object.

    @param central CBCentralManager instance
    @param peripheral Instance of connected peripheral
    @param error Error message
*/
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if ( error )
    {
        [DebugManager writeDebugLogWithLevel:DebugLevelErrors messsage:@"Disconnect error: %@ %i\r\n", error.description, error.code];
    }
    // Find SensorBox object for that peripheral
    if ( self.sensorBoxes )
    {
        [DebugManager writeDebugLogWithLevel:DebugLevelInfo messsage:@"Disconnect Peripheral: %@\r\n", peripheral.uuidString];
        
        for(int i=0; i<self.sensorBoxes.count; i++)
        {
            SensorBox *sb = [self.sensorBoxes objectAtIndex:i];
            if ([sb.peripheral uuidIsEqual:peripheral]) {
                // Report connection state to SensorBox object
                [sb reportConnectStateChanged:FALSE];
                return;
            }
        }
    }
}



//*************************************************************
//* 
//* Public Functions
//*
//*************************************************************


//! Returns string with current bluetooth state
/**
    Returns a string returning the current bluetooth state as text (in English).
    You may use CM.state to access the bluetooth state as code
    
    @return English text with Bluetooth state
*/ 
- (NSString*)getBluetoothStateText
{
    return [[[NSString alloc] initWithUTF8String:[self centralManagerStateToString:self.CM.state]] autorelease];
}

//! Scan for SensorBoxes
/** 
    Scans for SensorBoxes. This function is async. When SensorBoxes are found or timeout accoured, 
    the sensorBoxListUpdated is invoked. A parameter on sensorBoxListUpdated indicates if the scan
    is terminated.
    This function only looks for Flytec SensorBoxes. Any other BLE peripherals are ignored.
    The scan runs for the duration of timeout, but early found SensorBoxes are reported immediately.
    
    @param timeout Timeout for SensorBox scan in seconds.
    @return Error object describing the problem if the scan cannot start. (e.g. Bluetooth disabled) 
            nil if the start was successful.
*/     
- (NSError*) findSensorBoxes:(int) timeout 
{
    // Return error if bluetooth is not ready
    if ( ! [self checkBluetoothStateOn] ) 
    {
        NSString *description = nil;
        description = NSLocalizedString(@"Bluetooth state is off", @"");
        NSArray *objArray = [NSArray arrayWithObjects:description, nil];
        NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey, nil];
        NSDictionary *eDict = [NSDictionary dictionaryWithObject:objArray forKey:keyArray];
        return [[[NSError alloc]initWithDomain:ERRORDOMAIN_SENSORBOX code:ERROR_BLUETOOTHOFF userInfo:eDict] autorelease];
    }
    
    // Clear discovered flag
    if ( self.sensorBoxes ) 
    {
        for(int i=0; i<self.sensorBoxes.count; i++)
        {
            SensorBox *sb = [self.sensorBoxes objectAtIndex:i];
            sb.isDiscovered = FALSE;
        }
    }
    
    // Schedule timeout
    [NSTimer scheduledTimerWithTimeInterval:(float)timeout target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
    
    // Only look for sensorboxes
    CBUUID* uuid = [UUIDHelper StringToCBUUID:UUID_SENSORSERVICE];
    NSArray* uuid_array = [[[NSArray alloc] initWithObjects:uuid, nil] autorelease];
    
    // Start scaning
    [self.CM scanForPeripheralsWithServices:uuid_array options:0]; 
    return nil; // Started scanning OK !
}

//! Checks if the CBCentralManager is in ready state
/**
    This function returns if the CBCentralManager is in state to be used for SensorBoxLib. If this function 
    returns FALSE all other bluetooth functions will fail.
    
    @return TRUE if bluetooth is on and ready to be used
*/
- (BOOL) checkBluetoothStateOn 
{
    if (self->CM.state  != CBCentralManagerStatePoweredOn) {
        [DebugManager writeDebugLogWithLevel:DebugLevelErrors messsage:@"CoreBluetooth not correctly initialized !\r\n"];
        [DebugManager writeDebugLogWithLevel:DebugLevelErrors messsage:@"State = %d (%s)\r\n",self->CM.state,[self centralManagerStateToString:self.CM.state]];
        return FALSE;
    }
    return TRUE;
}

//! Sets the debug level
/**
    This function sets the debug level. Valid values are
    0 = no output
    1 = error messages only
    2 = info messages only
    3 = verbose output
    The function sets the debug level at the DebugManager. 
   
    @param level Debug level
*/
- (void) setDebugLevel:(int) level
{
    DebugManager* dm = [DebugManager sharedInstance];
    dm.debuglevel = level;
}


@end
