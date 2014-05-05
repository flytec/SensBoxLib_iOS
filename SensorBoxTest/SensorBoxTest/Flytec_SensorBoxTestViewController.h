//
//  Flytec_SensorBoxTestViewController.h
//  SensorBoxTest
//
//  Created by Aimago on 11.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SensorBoxSelectViewController.h"
#import "SensorBoxLib.h"
#import "FileTransferViewController.h"

@interface Flytec_SensorBoxTestViewController : UIViewController<SensorBoxManagerDelegate, SensorBoxDelegate, ServiceDelegate, SensorBoxSelectDelegate, UIAlertViewDelegate, FileTransferDelegate>


@property (retain, nonatomic) SensorBox* sensorBox;
@property (retain, nonatomic) NSString* doReconnectName;
@property (nonatomic) int batteryLastState;
@property (assign, nonatomic) IBOutlet UILabel *lableBLEStatus;
@property (assign, nonatomic) IBOutlet UILabel *labelSensorBoxFound;
@property (assign, nonatomic) IBOutlet UILabel *labelConnected;
@property (assign, nonatomic) IBOutlet UILabel *labelSatellites;
@property (assign, nonatomic) IBOutlet UILabel *labelPosition;
@property (assign, nonatomic) IBOutlet UILabel *labelTime;
@property (assign, nonatomic) IBOutlet UILabel *labelAltitude;
@property (assign, nonatomic) IBOutlet UILabel *labelVario;
@property (assign, nonatomic) IBOutlet UILabel *labelDeviceName;
@property (assign, nonatomic) IBOutlet UIButton *buttonConnect;
@property (assign, nonatomic) IBOutlet UIButton *buttonReconnect;
@property (assign, nonatomic) IBOutlet UIButton *buttonScan;
@property (assign, nonatomic) IBOutlet UIButton *buttonPEV;
@property (assign, nonatomic) IBOutlet UILabel *labelRSSI;
@property (assign, nonatomic) IBOutlet UILabel *labelGPSMovement;
@property (assign, nonatomic) IBOutlet UILabel *labelTemperature;
@property (retain, nonatomic) IBOutlet UILabel *labelFirmwareVersion;
@property (assign, nonatomic) IBOutlet UIImageView *imageLogging;
@property (assign, nonatomic) IBOutlet UIImageView *imageSDCard;
@property (assign, nonatomic) IBOutlet UIImageView *imageBattery;
@property (assign, nonatomic) IBOutlet UIButton *buttonStartLog;
@property (nonatomic) bool isLogging;
@property (assign, nonatomic) IBOutlet UIButton *buttonShutdown;
@property (assign, nonatomic) IBOutlet UIButton *buttonTest;
@property (nonatomic) int alertDialog;
@property (assign, nonatomic) IBOutlet UIButton *buttonQNH;
@property (retain, nonatomic) IBOutlet UIButton *buttonSetAlt;
@property (assign, nonatomic) IBOutlet UIButton *buttonQNE;
@property (retain, nonatomic) IBOutlet UILabel *labelMag;
@property (nonatomic) bool readCharacteristic;
@property(retain,nonatomic) NSTimer* statusUpdateTimer;


#define ALERT_SHUTDOWN 1
#define ALERT_QNH 2
#define ALERT_HEIGHT 3
#define ALERT_INTERVAL 4

@property (assign, nonatomic) NSTimer* rssiTimer;

- (IBAction)buttonScanPush:(id)sender;
- (IBAction)buttonConnectPush:(id)sender;
- (IBAction)buttonReconnectPush:(id)sender;
- (IBAction)buttonPEVPush:(id)sender;
//- (IBAction)buttonDisconnectPush:(id)sender;
- (IBAction)buttonStartLogPush:(id)sender;
- (IBAction)buttonShutdownPush:(id)sender;
- (IBAction)buttonTestPush:(id)sender;
- (IBAction)buttonQNHPush:(id)sender;
- (IBAction)buttonQNEPush:(id)sender;
- (IBAction)buttonFilePush:(id)sender;
- (IBAction)buttonSetAltPush:(id)sender;



@end
