//
//  Flytec_SensorBoxTestViewController.m
//  SensorBoxTest
//
//  Created by Aimago on 11.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Flytec_SensorBoxTestViewController.h"
#import "SensorBoxSelectViewController.h"
#import "FileTransferViewController.h"

@implementation Flytec_SensorBoxTestViewController
@synthesize imageLogging;
@synthesize imageSDCard;
@synthesize imageBattery;
@synthesize buttonStartLog;
@synthesize sensorBox;
@synthesize doReconnectName;
@synthesize lableBLEStatus;
@synthesize labelSensorBoxFound;
@synthesize labelConnected;
@synthesize labelPosition;
@synthesize labelSatellites;
@synthesize labelTime;
@synthesize labelVario;
@synthesize labelAltitude;
@synthesize labelDeviceName;
@synthesize buttonConnect;
@synthesize buttonPEV;
@synthesize buttonScan;
@synthesize buttonReconnect;
@synthesize labelRSSI;
@synthesize rssiTimer;
@synthesize labelGPSMovement;
@synthesize labelTemperature;
@synthesize batteryLastState;
@synthesize isLogging;
@synthesize buttonShutdown;
@synthesize readCharacteristic;
@synthesize statusUpdateTimer;

- (void)dealloc
{
    self.sensorBox = nil;
    self.doReconnectName = nil;
    [_labelMag release];
    [_buttonSetAlt release];
    [_labelFirmwareVersion release];
    [super dealloc];
}

// Update from sensorboxlib if bluetooth status has changed
- (void)bluetoothStateChanged:(BOOL)bluetoothOk
{
    self.lableBLEStatus.text = [[SensorBoxManager managerInstance] getBluetoothStateText];
    
    self.buttonScan.enabled = FALSE;
    self.buttonConnect.enabled = FALSE;
    self.buttonPEV.enabled = FALSE;
    if ( bluetoothOk )
    {
        self.buttonScan.enabled = TRUE;
        SensorBoxManager* m = [SensorBoxManager managerInstance];
        self.buttonConnect.enabled = ( m.sensorBoxes.count > 0 );

        if ( self.sensorBox ) {
            self.buttonPEV.enabled = self.sensorBox.isConnected;
        }
    }
}

// Action when new sensor box is found during discovery
// In case of reconnect automatically connect if searched box is found
- (void)sensorBoxListUpdated:(BOOL)finishedFind
{
    SensorBoxManager* mgr = [SensorBoxManager managerInstance];
    self.labelSensorBoxFound.text = [NSString stringWithFormat:@"%d", mgr.sensorBoxes.count];
    
    if ( self.doReconnectName ) 
    {
        SensorBoxManager* mgr = [SensorBoxManager managerInstance];
        for ( int i=0; i<mgr.sensorBoxes.count; i++ )
        {
            SensorBox* sb = [mgr.sensorBoxes objectAtIndex:i];
            if ( [self.doReconnectName compare:sb.deviceName] == NSOrderedSame )
            {
                [self connectSensorbox:sb];
                self.doReconnectName = nil;
                break;
            }
        }
        
        if ( self.doReconnectName &&  finishedFind )
        {
            // Messagebox
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error reconnecting" message:@"The device cannot be found!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
            [alert show];
            SensorBoxManager* mgr = [SensorBoxManager managerInstance];
            self.buttonConnect.enabled = ( mgr.sensorBoxes.count > 0 );
            self.buttonReconnect.enabled = TRUE;
        }
    }
    else 
    {
        SensorBoxManager* mgr = [SensorBoxManager managerInstance];
        self.buttonConnect.enabled = ( mgr.sensorBoxes.count > 0 );
    }
}

// Timer to request RSSI value 
- (void) rssiTimerEvent:(NSTimer *)timer
{
    if ( self.sensorBox && self.sensorBox.isConnected ) 
    {
        [self.sensorBox readRSSI];
    }
    else {
        [timer invalidate];
    }
}

// Not used anymore
-(void) statusUpdateTimerEvent:(NSTimer *)timer
{
    if ( self.sensorBox && self.sensorBox.isConnected )
    {
        SensorService* s1 = self.sensorBox.sensorService;
        [s1 readStatus];
    }
}

// Write GPS fix text depending on fix status
- (NSString*) getGPXFixString:(sens_gpsfix_t)fixstatus
{
    switch ( fixstatus )
    {
        case NoFix:
            return @"No Fix";
        case Fix2D:
            return @"2D Fix";
        case Fix3D:
            return @"3D Fix";
        case Fix2D_DGPS:
            return @"2D Fix + DGPS";
        case Fix3D_DGPS:
            return @"2D Fix + DGPS";
        default:
            return @"unknown";
            
    }
}

// Set battery level icon according to status
-(void) setBattery:(uint8_t)battery_level
{
    if ( self.batteryLastState != battery_level ) 
    {
        if ( battery_level > 100 ) {
            self.imageBattery.animationImages = [ NSArray arrayWithObjects:
                                                 [ UIImage imageNamed:@"bat_0.png"], [ UIImage  imageNamed:@"bat_1.png"],
                                                 [ UIImage imageNamed:@"bat_2.png"], [ UIImage imageNamed:@"bat_3.png"],
                                                 [ UIImage imageNamed:@"bat_4.png"], nil ];
            self.imageBattery.animationDuration = 3;
            self.imageBattery.animationRepeatCount = 0;
            [self.imageBattery startAnimating];
        }
        else
        {
            [self.imageBattery stopAnimating];
            if ( battery_level < 30 )
            {
                self.imageBattery.image = [ UIImage imageNamed:@"bat_0.png"];
            }
            else if ( battery_level < 50 )
            {
                self.imageBattery.image = [ UIImage imageNamed:@"bat_1.png"];
            }
            else if ( battery_level < 70 )
            {
                self.imageBattery.image = [ UIImage imageNamed:@"bat_2.png"];
            }
            else if ( battery_level < 90 )
            {
                self.imageBattery.image = [ UIImage imageNamed:@"bat_3.png"];
            }
            else 
            {
                self.imageBattery.image = [ UIImage imageNamed:@"bat_4.png"];
            }
        }
        self.batteryLastState = battery_level;
        self.imageBattery.hidden = false;
    }
}

// Callback when device is connected or disconnected
-(void) sensorBox:(SensorBox*)sensorBox connectStateChanged:(BOOL)connected
{
    if ( connected ) 
    {
        // Device connected
        self.labelConnected.text = @"connected";
        [self.buttonConnect setTitle:@"Disconnect" forState:UIControlStateNormal];
        self.buttonConnect.enabled = TRUE;
        self.buttonPEV.enabled = TRUE;
        self.buttonReconnect.enabled = FALSE;
        self.labelDeviceName.text = self.sensorBox.deviceName;
        self.buttonStartLog.enabled = TRUE;
        self.buttonShutdown.enabled = true;
        self.buttonQNE.enabled = true;
        self.buttonQNH.enabled = true;
        self.buttonTest.enabled = true;
        self.buttonSetAlt.enabled = true;
        
        DeviceInfoService* s = self.sensorBox.deviceInfoService;
        [s setDelegate:self];
        [s readFirmwareVersion];
        
        [self startReadCharacteristics];
        
        CommunicationService* s2 = self.sensorBox.communicationService;
        [s2 setDelegate:self];
        
        // Schedule RSSI update
        self.rssiTimer = [NSTimer scheduledTimerWithTimeInterval:(float)1 target:self selector:@selector(rssiTimerEvent:) userInfo:nil repeats:YES];
        
        // Disable sleep
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        
        // Notify
        SensorService* s1 = self.sensorBox.sensorService;
        [s1 setNotifyNavigation:true];
        [s1 setNotifyMovement:true];
        [s1 setNotifyStatus:true];

    }
    else
    {
        // Device disconnected
        [self.rssiTimer invalidate];
        self.rssiTimer = nil;
        
        [self.statusUpdateTimer invalidate];
        self.statusUpdateTimer = nil;
        
        self.labelConnected.text = @"disconnected";
        self.labelDeviceName.text = @"";
        [self.buttonConnect setTitle:@"Connect" forState:UIControlStateNormal];
        self.buttonConnect.enabled = TRUE;
        self.buttonPEV.enabled = FALSE;
        self.buttonReconnect.enabled = TRUE;
        self.batteryLastState = -1;
        self.imageBattery.hidden = true;
        self.imageLogging.hidden = true;
        self.imageSDCard.hidden = true;
        self.buttonStartLog.enabled = false;
        self.buttonShutdown.enabled = false;
        self.buttonQNE.enabled = false;
        self.buttonQNH.enabled = false;
        self.buttonTest.enabled = false;
        self.buttonSetAlt.enabled = false;
        
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
}

// Update RSSI value if its read has completed
-(void) sensorBox:(SensorBox*)sensorBox rssiReadCompleted:(NSNumber*)RSSI
{
    self.labelRSSI.text = [RSSI stringValue];
    //[self.sensorBox readRSSI];
}

// Callback if any characteristic value has been updated
-(void) sensorBox:(SensorBox*)sensorBox valueUpdated:(Service*)service characteristicUUID:(NSString*) uuid
{

    SensorService* s = self.sensorBox.sensorService;
    if ( s == service )
    {
        if ( [uuid isEqualToString:UUID_NAVIGATION] ) 
        {
            // Navigation characteristic
            sens_navigation_t navigation;
            BOOL retvalue = [s getNavigation:&navigation];
            if ( retvalue ) {
                self.labelPosition.text = [[[NSString alloc] initWithFormat:@"%f / %f", ((double)navigation.latitude/10000000.0), ((double)navigation.longitude/10000000.0)] autorelease];
                NSDate *nsdate = [[[NSDate alloc] initWithTimeIntervalSince1970:navigation.time] autorelease];
                self.labelTime.text = [nsdate description];
                
                //self.labelAltitude.text = [[[NSString alloc] initWithFormat:@"%1.1f m", ((double)navigation.baro_altitude_QNE)] autorelease];
                //self.labelVario.text = [[[NSString alloc] initWithFormat:@"%1.2f m/s", ((double)navigation.vario/100.0)] autorelease];
                
                self.imageLogging.hidden = !(navigation.status & SENS_STATUS_LOGGING);
                if ( ( navigation.status & SENS_STATUS_LOGGING && !isLogging ) || (!(navigation.status & SENS_STATUS_LOGGING) && isLogging ) )
                {
                    self.isLogging = (navigation.status & SENS_STATUS_LOGGING);
                    if ( self.isLogging ) [ self.buttonStartLog setTitle:@"Stop Log" forState:UIControlStateNormal];
                    if ( !self.isLogging ) [ self.buttonStartLog setTitle:@"Start Log" forState:UIControlStateNormal];
                }
            }
            // This char is updated with notify, no need to read again
            // Immediately request an update again
            //if ( self.readCharacteristic) [s readNavigation];
        }
        if ( [uuid isEqualToString:UUID_MOVEMENT] )
        {
            // Movement characteristic
            sens_movement_t movement;
            BOOL retvalue = [s getMovement:&movement];
            if ( retvalue ) {
                self.labelAltitude.text = [[[NSString alloc] initWithFormat:@"%1.1f m", ((double)movement.baro_altitude_QNE_cm/100.0)] autorelease];
                self.labelVario.text = [[[NSString alloc] initWithFormat:@"%1.2f m/s", ((double)movement.vario/100.0)] autorelease];
                self.labelGPSMovement.text = [[[NSString alloc] initWithFormat:@"%1.1f km/h / %1.0f°", ((double)movement.ground_speed/10*3.6), ((double)movement.gps_heading/10)] autorelease];
                double yaw = (double)movement.yaw / 10;
                //if ( yaw < 0 ) yaw += 360;
                self.labelMag.text = [[[NSString alloc] initWithFormat:@"%1.1f° (%1.0f/%1.0f)", yaw, (double)movement.roll/10, (double)movement.pitch/10] autorelease];
                
            }
            // Immediately request an update again
            // Not anymore, we do notify
            // if ( self.readCharacteristic) [s readMovement];
        }
        if ( [uuid isEqualToString:UUID_GPS2] )
        {
            // GPS secondary characteristic
            sens_gps2_t gps2;
            BOOL retvalue = [s getGPSSecondary:&gps2];
            if ( retvalue ) {
                self.labelSatellites.text = [[[NSString alloc] initWithFormat:@"Sats: %d (%@)", gps2.number_satelites, [self getGPXFixString:[s getGPSFixStatus:gps2.status]]] autorelease];
            }
            // Immediately request an update again
            // This is an example for usage without notify
            if ( self.readCharacteristic) [s readGPSSecondary];
        }
        if ( [uuid isEqualToString:UUID_STATUS] )
        {
            // Status characteristic
            sens_status_t status;
            BOOL retvalue = [s getStatus:&status];
            if ( retvalue ) {
                [self setBattery:status.battery_level];
                
                self.imageSDCard.hidden = !(status.status2 & SENS_STATUS2_SDCARD);
                self.labelTemperature.text = [[[NSString alloc] initWithFormat:@"%1.1f°C %1.1fhPa", ((double)status.temperature/10.0), ((double)status.pressure/100000.0)] autorelease];
                
            }
            // Don't read again, will be done in timer
        }
    }
    
    DeviceInfoService* ds = self.sensorBox.deviceInfoService;
    if ( ds == service )
    {
        if ( [uuid isEqualToString:UUID_FIRMWAREVERSION] )
        {
            self.labelFirmwareVersion.text = [ds getFirmwareVersion];
        }
    }
}

- (void)startReadCharacteristics
{
    self.readCharacteristic = true;
    SensorService* s1 = self.sensorBox.sensorService;
    [s1 setDelegate:self];
    // [s1 readMovement];
    //[s1 readNavigation];
    [s1 readGPSSecondary];
}
// Memory warning from iOS. Do nothing
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// on Load
- (void)viewDidLoad
{
    
    [super viewDidLoad];
	
    self.batteryLastState = -1;

    SensorBoxManager* mgr = [SensorBoxManager managerInstance];
    [mgr setDelegate:self];
    [mgr setDebugLevel:DebugLevelVerbose];

    self.buttonConnect.enabled = FALSE;
    self.buttonScan.enabled = TRUE;
    self.labelAltitude.text = @"";
    self.labelTime.text = @"";
    self.labelPosition.text = @"";
    self.labelVario.text = @"";
    self.labelSatellites.text = @"";
    self.labelSensorBoxFound.text = @"";
    self.labelConnected.text = @"";
    self.labelDeviceName.text = @"";
    self.labelGPSMovement.text = @"";
    self.labelTemperature.text = @"";
    self.labelMag.text = @"";
    self.labelFirmwareVersion.text = @"";
    self.imageBattery.hidden = true;
    self.imageLogging.hidden = true;
    self.imageSDCard.hidden = true;
    self.buttonStartLog.enabled = false;
    self.buttonShutdown.enabled = false;
    self.buttonQNE.enabled = false;
    self.buttonQNH.enabled = false;
    self.buttonTest.enabled = false;
    self.buttonSetAlt.enabled = false;

    //self.lableBLEStatus.text = [self.sensorBoxLib getBluetoothStateText];
    //[self bluetoothStateChanged:[self.sensorBoxLib checkBluetoothStateOn]];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *reconnectName = [prefs stringForKey:@"ReconnectDevice"];
    self.buttonReconnect.enabled = (reconnectName != nil);
    
    //[self.sensorBoxLib findSensorBoxes:5];
}

// on Unload
- (void)viewDidUnload
{
    [self setLableBLEStatus:nil];
    [self setLabelSensorBoxFound:nil];
    [self setLabelConnected:nil];
    [self setLabelPosition:nil];
    [self setLabelSatellites:nil];
    [self setLabelTime:nil];
    [self setLabelRSSI:nil];
    [self setLabelAltitude:nil];
    [self setLabelVario:nil];
    [self setButtonConnect:nil];
    [self setButtonPEV:nil];
    [self setButtonScan:nil];
    [self setButtonReconnect:nil];
    [self setLabelDeviceName:nil];
    
    [self setImageLogging:nil];
    [self setImageSDCard:nil];
    [self setImageBattery:nil];
    [self setLabelTemperature:nil];
    [self setButtonStartLog:nil];
    [self setButtonShutdown:nil];
    [self setButtonTest:nil];
    [self setButtonQNH:nil];
    [self setButtonQNE:nil];
    [self setLabelMag:nil];
    [self setButtonSetAlt:nil];
    [self setLabelFirmwareVersion:nil];
    [super viewDidUnload];
    
    self.sensorBox = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

// Force portrait orientation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
    //!= UIInterfaceOrientationPortraitUpsideDown);
}

// Button Push pressed. Discover boxes
- (IBAction)buttonScanPush:(id)sender 
{
    [[SensorBoxManager managerInstance] findSensorBoxes:5];
}

// Connect to a specific sensorbox
- (void)connectSensorbox:(SensorBox*)inSensorBox
{
    self.sensorBox = inSensorBox;
    [self.sensorBox setDelegate:self];
    [self.sensorBox connect];
    [self.buttonConnect setTitle:@"Disconnect" forState:UIControlStateNormal];
    self.buttonConnect.enabled = FALSE;
    self.buttonReconnect.enabled = FALSE;
    self.labelConnected.text = @"wait...";
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:self.sensorBox.deviceName forKey:@"ReconnectDevice"];
    [prefs synchronize];
}

// Button reconnect pressed
- (IBAction)buttonReconnectPush:(id)sender
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *reconnectName = [prefs stringForKey:@"ReconnectDevice"];
    self.buttonReconnect.enabled = (reconnectName != nil);
    
    if (( ! self.sensorBox || ! self.sensorBox.isConnected ) && reconnectName != nil )
    {
        self.doReconnectName = reconnectName;
        [[SensorBoxManager managerInstance] findSensorBoxes:2];
        self.buttonReconnect.enabled = FALSE;
        self.buttonConnect.enabled = FALSE;
    }
    
}

//Button connect pressed. This can be a connect or disconnect request
- (IBAction)buttonConnectPush:(id)sender
{

    if ( self.sensorBox && self.sensorBox.isConnected ) 
    {  
        [self.sensorBox disconnect];
        self.buttonConnect.enabled = FALSE;
        self.buttonReconnect.enabled = FALSE;
    }
    else
    {
        UIStoryboard* storyboard = self.storyboard;
        
        SensorBoxSelectViewController* selectController = [storyboard instantiateViewControllerWithIdentifier:@"selectSensorController"];
        selectController.delegate = self;
        SensorBoxManager* mgr = [SensorBoxManager managerInstance];
        selectController.sensorBoxes = mgr.sensorBoxes;
        UINavigationController* navigationController = [[[UINavigationController alloc] initWithRootViewController:selectController] autorelease];
        [self presentViewController:navigationController animated:YES completion:nil];
    }
}

// Pilot event button pressed
- (IBAction)buttonPEVPush:(id)sender {
    
    CommunicationService* s1 = self.sensorBox.communicationService;
    CommMessageEvent* msg = [[[CommMessageEvent alloc] initWithEventCode:COMMMESSAGE_EVENT_PEV expectResponse:TRUE] autorelease];
    [s1 sendMessage:msg];
    
    
}

// Callback after select sensorbox dialog
- (void)selectDoneViewController:(SensorBoxSelectViewController*) selectController
                   selectedSensorBox:(SensorBox*)inSensorBox;
{
    [self dismissModalViewControllerAnimated:YES];
    if ( inSensorBox && ! ( self.sensorBox && self.sensorBox.isConnected ) ) 
    {
        // Connect
        [self connectSensorbox:inSensorBox];
    }
    
}

// Received message from FlySens device thorugh Communication service. This usually means ACK/NACK for event messages
// or reply to Settings message.
-(void) messageReceived:(CommunicationService*)service message:(CommMessage*) message
{
    if ( [ message isKindOfClass:[CommMessageEvent class]] )
    {
        CommMessageEvent* msgEvent = (CommMessageEvent*)message;
        if ( msgEvent.eventCode == COMMMESSAGE_EVENT_PEV ) {
            if ( msgEvent.messageReplyStatus == MessageReplyStatusAck )
            {
                UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Acknowledge" message:@"The event was acknowledged" delegate:nil   cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
                [alert show];
            }
        }
    }
    if ( [ message isKindOfClass:[CommMessageSettings class]] )
    {
        CommMessageSettings* msgSettings = (CommMessageSettings*)message;
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Setting" message:msgSettings.receivedString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        [alert show];
    }
    /*if ( [ message isKindOfClass:[CommMessageFile class]] )
    {
        [self.sensorBox.fileTransferHelper messageReceived:service message:message];
    }*/
}

-(void) timeoutWaitingResponse:(CommunicationService*) service message:(CommMessage*)message
{
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"CommService" message:@"Received Timeout" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
    [alert show];
}

// Start logging button
- (IBAction)buttonStartLogPush:(id)sender {
    if ( self.isLogging ) {
        CommunicationService* s1 = self.sensorBox.communicationService;
        CommMessageEvent* msg = [[[CommMessageEvent alloc] initWithEventCode:COMMMESSAGE_EVENT_STOPLOG expectResponse:false] autorelease];
        [s1 sendMessage:msg];
    }
    else {
        CommunicationService* s1 = self.sensorBox.communicationService;
        CommMessageEvent* msg = [[[CommMessageEvent alloc] initWithEventCode:COMMMESSAGE_EVENT_STARTLOG expectResponse:false] autorelease];
        [s1 sendMessage:msg];
    }
}

// Shutdown Button
- (IBAction)buttonShutdownPush:(id)sender {
    self.alertDialog = ALERT_SHUTDOWN;
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Shutdown" message:@"Are you sure you want shutdown the device?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] autorelease];
    [alert show];
}

// Test Button
// This button is used by Aimago for testing features. 
- (IBAction)buttonTestPush:(id)sender {
    
    self.alertDialog = ALERT_INTERVAL;
    UIAlertView * alert = [[[UIAlertView alloc] initWithTitle:@"Interval" message:@"Please enter interval for Mov:" delegate:self cancelButtonTitle:@"Continue" otherButtonTitles:nil] autorelease];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField * alertTextField = [alert textFieldAtIndex:0];
    alertTextField.keyboardType = UIKeyboardTypeNumberPad;
    alertTextField.placeholder = @"Interval";
    [alert show];
    
}

// Change to QNH corrected output and adjust QNH. Also ask user to supply QNH
- (IBAction)buttonQNHPush:(id)sender {
    CommunicationService* s1 = self.sensorBox.communicationService;
    CommMessageSettings* msg2 = [[[CommMessageSettings alloc] initWithString:@"BLE_UseQNH_Mov=1" expectResponse:FALSE] autorelease];
    [s1 sendMessage:msg2];

    self.alertDialog = ALERT_QNH;
    UIAlertView * alert = [[[UIAlertView alloc] initWithTitle:@"Set QNH" message:@"Please enter QNH:" delegate:self cancelButtonTitle:@"Continue" otherButtonTitles:nil] autorelease];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField * alertTextField = [alert textFieldAtIndex:0];
    alertTextField.keyboardType = UIKeyboardTypeNumberPad;
    alertTextField.placeholder = @"QNH";
    [alert show];
}

// Change to non-corrected QNE mode
- (IBAction)buttonQNEPush:(id)sender {
    CommunicationService* s1 = self.sensorBox.communicationService;
    CommMessageSettings* msg2 = [[[CommMessageSettings alloc] initWithString:@"BLE_UseQNH_Mov=0" expectResponse:FALSE] autorelease];
    [s1 sendMessage:msg2];
}

// Alert View callback
// This is used for shutdown confirmation or QNHH entry
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Confirmation for shutdown
    if ( self.alertDialog == ALERT_SHUTDOWN && buttonIndex == 1 )
    {
        CommunicationService* s1 = self.sensorBox.communicationService;
        CommMessageEvent* msg = [[[CommMessageEvent alloc] initWithEventCode:COMMMESSAGE_EVENT_SHUTDOWN expectResponse:false] autorelease];
        [s1 sendMessage:msg];
    }
    
    if ( self.alertDialog == ALERT_QNH )
    {
        int qnh = (int)([[[alertView textFieldAtIndex:0] text] doubleValue]) * 100;
        NSString* setting = [[[NSString alloc] initWithFormat:@"QNH_Pa=%i", qnh] autorelease];
        
        CommunicationService* s1 = self.sensorBox.communicationService;
        CommMessageSettings* msg = [[[CommMessageSettings alloc] initWithString:setting expectResponse:FALSE] autorelease];
        [s1 sendMessage:msg];
    }
    
    if ( self.alertDialog == ALERT_HEIGHT )
    {
        int height = (int)([[[alertView textFieldAtIndex:0] text] doubleValue]);
        NSString* setting = [[[NSString alloc] initWithFormat:@"BLE_QNH_from_m=%i", height] autorelease];
        
        CommunicationService* s1 = self.sensorBox.communicationService;
        CommMessageSettings* msg = [[[CommMessageSettings alloc] initWithString:setting expectResponse:FALSE] autorelease];
        [s1 sendMessage:msg];
    }
    if ( self.alertDialog == ALERT_INTERVAL )
    {
        int interval = (int)([[[alertView textFieldAtIndex:0] text] doubleValue]);
        NSString* setting = [[[NSString alloc] initWithFormat:@"BLE_MsgRate_Mov=%i", interval] autorelease];
        
        CommunicationService* s1 = self.sensorBox.communicationService;
        
        CommMessageSettings* msg = [[[CommMessageSettings alloc] initWithString:setting expectResponse:TRUE] autorelease];
        [s1 sendMessage:msg];
    }
}



- (IBAction)buttonFilePush:(id)sender {
    UIStoryboard* storyboard = self.storyboard;
    
    FileTransferViewController* fileController = [storyboard instantiateViewControllerWithIdentifier:@"fileTransferController"];
    fileController.delegate = self;
    fileController.sensorBox = self.sensorBox;
    
    UINavigationController* navigationController = [[[UINavigationController alloc] initWithRootViewController:fileController] autorelease];
    [self presentViewController:navigationController animated:YES completion:nil];
    self.readCharacteristic = false;
}

- (IBAction)buttonSetAltPush:(id)sender {
    CommunicationService* s1 = self.sensorBox.communicationService;
    CommMessageSettings* msg2 = [[[CommMessageSettings alloc] initWithString:@"BLE_UseQNH_Mov=1" expectResponse:FALSE] autorelease];
    [s1 sendMessage:msg2];
    
    self.alertDialog = ALERT_HEIGHT;
    UIAlertView * alert = [[[UIAlertView alloc] initWithTitle:@"Set Altitude" message:@"Please enter Altitude (m):" delegate:self cancelButtonTitle:@"Continue" otherButtonTitles:nil] autorelease];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField * alertTextField = [alert textFieldAtIndex:0];
    alertTextField.keyboardType = UIKeyboardTypeNumberPad;
    alertTextField.placeholder = @"Altitude";
    [alert show];
}

- (void)returnFromDialog:(FileTransferViewController*) fileController
{
    [self dismissModalViewControllerAnimated:YES];
    
    [self startReadCharacteristics];
}

@end
