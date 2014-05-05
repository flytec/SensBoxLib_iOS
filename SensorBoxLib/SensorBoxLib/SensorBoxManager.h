//
//  SensorBoxManager.h
//  SensorBoxManager
//
//  Created by Aimago/man 
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  26.04.2012   man    First Release
//  06.06.2012   man    Finalize & Documentation
//  07.11.2013   man    Added file transfer helper
//  24.12.2013   man    Renamed to SensorBoxManager, changed to singleton, improved debug outputs
//  13.03.2014   man    Implemented suggested changes by Hardwig


#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


//! Delegate for SensorBoxLib callbacks
/**
 This delegate is used to update the status of the library to the callee
 */
@protocol SensorBoxManagerDelegate <NSObject>
@optional
//! Reports bluetooth state change
/**
 bluetoothStateChanged is called when a change of bluetooth state is reported by
 the CoreBluetooth
 
 @param bluetoothOk TRUE if bluetooth status is ok to be used for SensorBoxLib
 */
-(void) bluetoothStateChanged:(BOOL)bluetoothOk;

//! Called during findSensorBox when list is updated
/**
 The function might be called multiple times during the findSensorBox. The last call is
 inidcated with finishedFind set to TRUE.
 
 @param finishedFind TRUE if findSensorBox has terminated (timeout)
*/
-(void) sensorBoxListUpdated:(BOOL)finishedFind;
@required

@end

//! Main SensorBoxLib library class
/**
    This class is the entrypoint to use SensorBoxLib. Use a instance of this class
    to find SensorBox and connect to them.
*/
@interface SensorBoxManager : NSObject<CBCentralManagerDelegate>

//! Delegate to report state changes and found SensorBoxes to
@property (nonatomic, assign) id <SensorBoxManagerDelegate> delegate;

//! Reference to the CBCentralManager instance. 
/** 
    This single instance is used throughout the library
*/  
@property (retain, nonatomic) CBCentralManager *CM;

//! List of all sensorboxes found
@property (retain, nonatomic) NSMutableArray *sensorBoxes;

//! Reference to the currently active SensorBox
//@property (strong, nonatomic) SensorBox* activeSensorBox;

// Public functions are documented in .m file
- (NSString*)getBluetoothStateText;
- (BOOL) checkBluetoothStateOn;
- (NSError*) findSensorBoxes:(int) timeout;
- (void) setDebugLevel:(int) level;

+ (id)managerInstance;

@end

