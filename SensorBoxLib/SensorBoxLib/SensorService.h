//
//  SensorService.h
//  SensorBoxLib
//
//  Created by Aimago/man 
//  Copyright (c) 2012-2013 Aimago SA & Flytec AG. All rights reserved.
//
//  History
//  =======
//  26.04.2012   man    First Release
//  06.06.2012   man    Finalize & Documentation
//  07.11.2013   man    Updated STATUS2 flags and unit descriptions

#import <Foundation/Foundation.h>

#import "Service.h"

//! Service class for SensorService service
/** 
 *  This service is the main service of a sensor box. It allows reading
 *  the real-time data for all sensors including barometric, GPS and motion. 
*/  
@interface SensorService : Service

//! UUID for SensorService
#define UUID_SENSORSERVICE @"<aba27100 143b4b81 a444edcd 0000f020>"

//! UUID for Navigation characteristic
#define UUID_NAVIGATION @"<aba27100 143b4b81 a444edcd 0000f022>"

//! UUID for Movement characteristic
#define UUID_MOVEMENT @"<aba27100 143b4b81 a444edcd 0000f023>"

//! UUID for GPS secondary characteristic
#define UUID_GPS2 @"<aba27100 143b4b81 a444edcd 0000f024>"

//! UUID for Status characteristic
#define UUID_STATUS @"<aba27100 143b4b81 a444edcd 0000f025>"

//! Status flag RTC updated from GPS
#define SENS_STATUS_TIME_GPS 0x08

//! Status flag charging
#define SENS_STATUS_CHARGING 0x10

//! Status flag battery low
#define SENS_STATUS_BATLOW   0x20

//! Status flag logging
#define SENS_STATUS_LOGGING  0x40

//! Status2 flag SDCard inserted
#define SENS_STATUS2_SDCARD  0x01

//! Status2 flag Communication Service Ready
#define SENS_STATUS2_COMMREADY 0x02

//! Status2 flag File Transfer Service Ready
#define SENS_STATUS2_FILEREADY 0x04


//! Structure for navigation characteristic
typedef struct {
    //! Current date/time in unixtime format
    uint32_t time;                 
    //! Position latitude in ° * 10e7
    int32_t latitude;               
    //! Position longitude in ° * 10e7
    int32_t longitude;              
    //! Height above mean sea level from GPS in meter
    int16_t gps_height_msl;        
    //! Altitude barometric. Usually in QNE (1013.25hPa) in meter, but can be changed with settings to give QNH in meters. See documentation.
    int16_t baro_altitude_QNE;      
    //! Variometer barometric in cm/s filtered for 1Hz
    int16_t vario;                  
    //! Status flag. See characteristic documentation for details.
    uint8_t status;
} sens_navigation_t;

//! Structure for movement characteristic
typedef struct {
    //! Altitude barometric. Usually with QNE (1013.25hPa) in centimeter, but can be changed with settings to give QNH. See documentation.
    int32_t baro_altitude_QNE_cm;   
    //! Variometer barometeric in cm/s filtered for 8Hz
    int16_t vario;                  
    //! Groundspeed from GPS in dm/s
    int16_t ground_speed;           
    //! Heading from GPS in ° * 10
    int16_t gps_heading;
    //! Pitch in ° * 10, range +-180°
    int16_t pitch;
    //! Yaw in ° * 10, range +-180°
    int16_t yaw;
    //! Roll in ° * 10, range +-180°
    int16_t roll;
    //! Acceleration: in "g" * 10
    int16_t accel;
    //! Status flag. See characteristic documentation for details.
    uint8_t status;    
} sens_movement_t;

//! Structure for secondary GPS characteristic
typedef struct {
    //! GPS Horizontal accuracy in decimeter
    uint16_t gps_hacc;
    //! GPS Vertical accuracy in decimeter
    uint16_t gps_vacc;
    //! Height above ellipsoid from GPS in meter
    int16_t gps_height_ellipsoid;   
    //! Number of satelites used for fix
    uint8_t number_satelites;      
    //! Status flag. See characteristic documentation for details.
    uint8_t status;
} sens_gps2_t;

//! Structure for status characteristic
typedef struct {
    //! Current date/time in unixtime format
    uint32_t time;                  
    //! Battery level in percent.
    /**
    * Remark: The battery level has only discrete values
    */
    uint8_t battery_level; 
    //! Logging level in percent
    /** 
    * Percent of used space in the internal flash buffer for logging.
    */
    uint8_t logging_level;          
    //! Temperature in °C * 10
    int16_t temperature;            
    //! Status flag. See characteristic documentation for details.
    uint8_t status;
    //! Status2 flag. See characteristic documentation for details.
    uint8_t status2;
    //! QNH in Pa * 10
    uint16_t qnh;
    //! Current air pressure filtered 1Hz in mPa
    int32_t pressure;
} sens_status_t;

//! GPS fix status
/**
 Posible status values for GPS fix.
 Differential GPS is not used yet.
*/
enum {
	NoFix = 0,
	Fix2D = 1,
    Fix3D = 2,
    Fix2D_DGPS = 3,
    Fix3D_DGPS = 4,
    Fix_unknown
};
typedef NSInteger sens_gpsfix_t;

- (BOOL) readNavigation;
- (BOOL) getNavigation:(sens_navigation_t*)navigation;
- (void) setNotifyNavigation:(Boolean)enable;
- (BOOL) readMovement;
- (BOOL) getMovement:(sens_movement_t*)movement;
- (void) setNotifyMovement:(Boolean)enable;
- (BOOL) readGPSSecondary;
- (BOOL) getGPSSecondary:(sens_gps2_t*)gps2;
- (void) setNotifyGPSSecondary:(Boolean)enable;
- (BOOL) readStatus;
- (BOOL) getStatus:(sens_status_t*)status;
- (void) setNotifyStatus:(Boolean)enable;

- (sens_gpsfix_t) getGPSFixStatus:(uint8_t)status;

@end
