//
//  FileTransferViewController.m
//  SensorBoxTest
//
//  Created by Aïmago on 10/17/13.
//
//

#import "FileTransferViewController.h"

@interface FileTransferViewController ()

@end

@implementation FileTransferViewController

@synthesize delegate;
@synthesize sensorBox;
@synthesize fileList;
@synthesize pickerView;
@synthesize selectedFileName;
@synthesize activityIndicatorView;
@synthesize abortButton;
@synthesize statusUpdateTimer;
@synthesize listButton;
@synthesize initButton;
@synthesize startDownloadDate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
            }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    if ( self.statusUpdateTimer != nil )
    {
        [self.statusUpdateTimer invalidate];
        self.statusUpdateTimer = nil;
    }
        
    self.sensorBox = nil;
    self.delegate = nil;
    self.fileList = nil;
    self.pickerView = nil;
    self.selectedFileName = nil;
    self.activityIndicatorView = nil;
    self.progerssBar = nil;
    self.abortButton = nil;
    self.initButton = nil;
    self.startDownloadDate = nil;
    
    [self setLabelSize:nil];
    [self setLabelTime:nil];
    [super viewDidUnload];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [self.statusUpdateTimer invalidate];
    self.statusUpdateTimer = nil;
}

-(void)viewWillAppear:(BOOL)animated
{
    self.downloadButton.enabled = false;
    self.abortButton.enabled = false;
    self.initButton.enabled = false;
    self.listButton.enabled = false;
    self.labelSize.text = @"";
    self.labelTime.text = @"";
    self.progerssBar.progress = 0;
    
    self.statusUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:(float)0.5 target:self selector:@selector(statusUpdateTimerEvent:) userInfo:nil repeats:YES];
    
    [self.sensorBox.fileTransferHelper setDelegate:self];
}


-(void) statusUpdateTimerEvent:(NSTimer *)timer
{
    if ( self.sensorBox != nil && self.sensorBox.isConnected )
    {
        SensorService* s = self.sensorBox.sensorService;
        sens_status_t status;
        BOOL retvalue = [s getStatus:&status];
        if ( retvalue )
        {
            if ( ( ( status.status2 & SENS_STATUS2_COMMREADY ) != 0 ) && ( ( status.status2 & SENS_STATUS2_FILEREADY ) != 0 ) )
            {
                self.initButton.enabled = false;
                self.abortButton.enabled = true;
                self.listButton.enabled = true;
                self.downloadButton.enabled = ( self.selectedFileName != nil );
            }
            else
            {
                self.initButton.enabled = true;
                self.abortButton.enabled = false;
                self.listButton.enabled = false;
                self.downloadButton.enabled = false;
            }
        }
        else
        {
            self.initButton.enabled = false;
            self.abortButton.enabled = false;
            self.listButton.enabled = false;
            self.downloadButton.enabled = false;
        }
    }
    else
    {
        self.initButton.enabled = false;
        self.abortButton.enabled = false;
        self.listButton.enabled = false;
        self.downloadButton.enabled = false;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonCancelPush:(id)sender
{
    [[self delegate] returnFromDialog:self];
}

- (IBAction)buttonListPush:(id)sender
{
    // Make sure we are the delegat
    [self.sensorBox.fileTransferHelper setDelegate:self];
    
    [self.sensorBox.fileTransferHelper beginGetFiles:@"/tracks" includeFolders:false];
    
    self.activityIndicatorView = [self showSimpleActivityIndicatorOnView:[self view]];
}

- (IBAction)buttonDownloadPush:(id)sender
{
    NSString* fn = @"/tracks/";
    fn = [fn stringByAppendingString:self.selectedFileName];
    [self.sensorBox.fileTransferHelper openFile:fn mode:FileOpenModeReadIGCHuffmann];
    self.startDownloadDate = [[[NSDate alloc] initWithTimeIntervalSinceNow:0] autorelease];
}

- (IBAction)buttonAbortPush:(id)sender
{
    
    [self.sensorBox.fileTransferHelper abortTransfer];
    
}

- (IBAction)buttonInitPush:(id)sender {
    CommunicationService* s = self.sensorBox.communicationService;
    CommMessageEvent* msg = [[[CommMessageEvent alloc] initWithEventCode:COMMMESSAGE_EVENT_FILETRANSFER expectResponse:FALSE] autorelease];
    [s sendMessage:msg];
}

-(void) getFilesFinished:(FileTransferHelper*)helper fileList:(NSMutableArray*) inFileList;
{
    self.fileList = inFileList;
    [self.pickerView reloadAllComponents];
    
    [self.activityIndicatorView stopAnimating];
    self.activityIndicatorView = nil;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    //if ( self.fileList == nil ) return 0;
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if ( self.fileList == nil ) return 0;
    return self.fileList.count;
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if ( self.fileList == nil ) return nil;
    FileInfoEntry* entry = [self.fileList objectAtIndex:row];
    return entry.filename;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    
    FileInfoEntry* entry = [self.fileList objectAtIndex:row];
    
    if ( entry != nil )
    {
        self.selectedFileName = entry.filename;
    }
    else
    {
        self.selectedFileName = nil;
    }
}

-(void) openFileFinished:(FileTransferHelper*)helper result:(FileOpenResult) result
{
    // Close it immediateley
    if ( result != FileOpenSuccess )
    {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Download" message:@"Cannot open file" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        [alert show];
        
        [helper closeFile]; // Ensure that any file is closed;
    }
    else
    {
        [helper startReadOpenFile:self.selectedFileName];
    }
}

-(void) readFileReady:(FileTransferHelper*)helper size:(NSInteger) size
{
    self.labelSize.text = [[[NSString alloc] initWithFormat:@"%1.1f kB", (double)size/1024.0] autorelease];
}

-(void) closeFileFinished:(FileTransferHelper*)helper result:(FileCloseResult) result crc:(uint16_t)crc
{
    
    if ( helper.receivedDataCrc == crc )
    {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Download" message:@"File downloaded successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        [alert show];
    }
    else
    {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Download" message:@"File invalid" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        [alert show];
    }
    
}

-(void) abortFinished:(FileTransferHelper *)helper
{
    [helper closeFile];
}

-(void) readFileProgress:(FileTransferHelper *)helper result:(FileReadStatus)status progress:(float)progress
{
    self.progerssBar.progress = progress;
    
    if ( status == FileReadFailureTimeout )
    {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Download" message:@"Read timeout" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        [alert show];
    }
    else if ( status == FileReadFailureSync )
    {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Download" message:@"Read out of sync" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        [alert show];
    }
    else if ( status == FileReadSuccess )
    {
        [self.sensorBox.fileTransferHelper closeFile];
    }
    else if ( status == FileReadInProgress )
    {
        NSTimeInterval diff = [[NSDate date] timeIntervalSinceDate:self.startDownloadDate];
        self.labelTime.text = [[[NSString alloc] initWithFormat:@"%1.1f sec", diff] autorelease];

    }
}

- (UIActivityIndicatorView*) showSimpleActivityIndicatorOnView:(UIView*)view
{
    CGSize viewSize = view.bounds.size;
    
    UIActivityIndicatorView *av = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]autorelease];
    av.center = CGPointMake(viewSize.width / 2.0, viewSize.height / 2.0);
    
    [view addSubview:av];
    
    [av startAnimating];
    
    return av;
}


- (void)dealloc {
    [_labelSize release];
    [_labelTime release];
    [super dealloc];
}
@end
