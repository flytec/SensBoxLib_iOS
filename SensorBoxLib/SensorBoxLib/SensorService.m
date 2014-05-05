//
//  SensorService.m
//  SensorBoxLib
//
//  Created by Aimago/man 
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  26.4.2012   man    First Release
//  06.6.2012   man    Finalize & Documentation
//  13.03.2014   man    Implemented suggested changes by Hardwig

#import "SensorService.h"

@implementation SensorService

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

//! Requests update for navigation characteristic
/**
 *  Requests read for navigation characteristic. Once the data is updated a 
 *  callback will be invoked.
 *  Upon completion (callback) the value can be read using getNavigation 
 *
 *  @returns FALSE if the characteristic is not found
 */       
- (BOOL) readNavigation
{
    return [self readWithUUIDString:UUID_NAVIGATION];
}

//! Returns data for navigation characteristic
/**
 *  Before calling this function, readNavigation must be called and its 
 *  completion must be reported on the delegate.
 *  This function returns the last read data.
 *  
 *  @returns structure with navigational data from FlySens
*/  
- (BOOL) getNavigation:(sens_navigation_t*)navigation
{
    NSData* data = [self getDataWithUUIDString:UUID_NAVIGATION];
    
    [data getBytes:navigation length:sizeof(sens_navigation_t)];
    
    return TRUE;
}

//! Set notify status for navigation characteristic
/**
 * If set tue true the notify is enabled and new data is automatically
 * transmitted. The message rate can be set using the BLE_MsgRate_Nav
 * setting.
 *
 * @param enable TRUE if notify should be enabled
 */
- (void) setNotifyNavigation:(Boolean)enable
{
    [self setNotifyWithUUIDString:UUID_NAVIGATION enableNotify:enable];
}

//! Requests update for movement characteristic
/**
 *  Requests read for movement characteristic. Once the data is updated a 
 *  callback will be invoked.
 *  Upon completion (callback) the value can be read using getMovement 
 *
 *  @returns FALSE if the characteristic is not found
 */   
- (BOOL) readMovement
{
    return [self readWithUUIDString:UUID_MOVEMENT];
}

//! Returns data for movement characteristic
/**
 *  Before calling this function, readMovement must be called and its 
 *  completion must be reported on the delegate.
 *  This function returns the last read data.
 *  
 *  @returns structure with movement data from FlySens
 */ 
- (BOOL) getMovement:(sens_movement_t *)movement
{
    NSData* data = [self getDataWithUUIDString:UUID_MOVEMENT];
    
    [data getBytes:movement length:sizeof(sens_movement_t)];
    
    return TRUE;
}

//! Set notify status for movement characteristic
/**
 * If set tue true the notify is enabled and new data is automatically
 * transmitted. The message rate can be set using the BLE_MsgRate_Mov 
 * setting.
 *
 * @param enable TRUE if notify should be enabled
*/
- (void) setNotifyMovement:(Boolean)enable
{
    [self setNotifyWithUUIDString:UUID_MOVEMENT enableNotify:enable];
}

//! Requests update for secondary GPS characteristic
/**
 *  Requests read for secondary GPS characteristic. Once the data is updated a 
 *  callback will be invoked.
 *  Upon completion (callback) the value can be read using getGPSSecondary 
 *
 *  @returns FALSE if the characteristic is not found
 */   
- (BOOL) readGPSSecondary
{
    return [self readWithUUIDString:UUID_GPS2];
}

//! Returns data for secondary GPS characteristic
/**
 *  Before calling this function, readGPSSecondary must be called and its 
 *  completion must be reported on the delegate.
 *  This function returns the last read data.
 *  
 *  @returns structure with secondary GPS data from FlySens
 */ 
- (BOOL) getGPSSecondary:(sens_gps2_t *)gps2
{
    NSData* data = [self getDataWithUUIDString:UUID_GPS2];
    
    [data getBytes:gps2 length:sizeof(sens_gps2_t)];
    
    return TRUE;
}

//! Set notify status for secondary GPS characteristic
/**
 * If set tue true the notify is enabled and new data is automatically
 * transmitted. The message rate can be set using the BLE_MsgRate_Gps
 * setting.
 *
 * @param enable TRUE if notify should be enabled
 */
- (void) setNotifyGPSSecondary:(Boolean)enable
{
    [self setNotifyWithUUIDString:UUID_GPS2 enableNotify:enable];
}

//! Requests update for status characteristic
/**
 *  Requests read for status characteristic. Once the data is updated a 
 *  callback will be invoked.
 *  Upon completion (callback) the value can be read using getStatus
 *
 *  @returns FALSE if the characteristic is not found
 */   
- (BOOL) readStatus
{
    return [self readWithUUIDString:UUID_STATUS];
}

//! Returns data ofr status characteristic
/**
 *  Before calling this function, readStatus must be called and its 
 *  completion must be reported on the delegate.
 *  This function returns the last read data.
 *  
 *  @returns structure with status from FlySens
 */ 
- (BOOL) getStatus:(sens_status_t *)status
{
    [[self getDataWithUUIDString:UUID_STATUS] getBytes:status length:sizeof(sens_status_t)];
    
    return TRUE;
}

//! Set notify status for status characteristic
/**
 * If set tue true the notify is enabled and new data is automatically
 * transmitted. The message rate can be set using the BLE_MsgRate_Sts
 * setting.
 *
 * @param enable TRUE if notify should be enabled
 */
- (void) setNotifyStatus:(Boolean)enable
{
    [self setNotifyWithUUIDString:UUID_STATUS enableNotify:enable];
}

//! Extracts the GPS fix information from the status flags
/**
  * Extracts the GPS fix status from the status flags
  * 
  * @param status status flags returned with any SensorService characteristic
  * @returns GPS fix status
  */
- (sens_gpsfix_t)getGPSFixStatus:(uint8_t)status
{
    uint8_t fix = (status & 0x7);
    if ( fix > 4 ) return Fix_unknown;
    return (sens_gpsfix_t)fix;
}




@end
