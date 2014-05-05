//
//  FileTransferViewController.h
//  SensorBoxTest
//
//  Created by Aïmago on 10/17/13.
//
//

#import <UIKit/UIKit.h>
#import "SensorBoxLib.h"

@protocol FileTransferDelegate;


@interface FileTransferViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, FileTransferHelperDelegate>

@property (assign, nonatomic) id <FileTransferDelegate> delegate;
@property (assign, nonatomic) SensorBox* sensorBox;

@property (assign, nonatomic) IBOutlet UIPickerView *pickerView;

@property (assign, nonatomic) IBOutlet UIButton *downloadButton;

@property (assign, nonatomic) IBOutlet UIButton *abortButton;

@property (assign, nonatomic) IBOutlet UIButton *listButton;

@property (assign, nonatomic) IBOutlet UIButton *initButton;
@property (retain, nonatomic) IBOutlet UILabel *labelSize;
@property (retain, nonatomic) IBOutlet UILabel *labelTime;

@property (assign, nonatomic) IBOutlet UIProgressView *progerssBar;

@property (retain, nonatomic) NSMutableArray* fileList;

@property (retain, nonatomic) NSString* selectedFileName;

@property (retain, nonatomic) UIActivityIndicatorView* activityIndicatorView;

@property (retain, nonatomic) NSTimer* statusUpdateTimer;

@property (retain, nonatomic) NSDate* startDownloadDate;


- (IBAction)buttonCancelPush:(id)sender;
- (IBAction)buttonListPush:(id)sender;

- (IBAction)buttonDownloadPush:(id)sender;
- (IBAction)buttonAbortPush:(id)sender;
- (IBAction)buttonInitPush:(id)sender;

- (UIActivityIndicatorView*) showSimpleActivityIndicatorOnView:(UIView*)view;

@end


@protocol FileTransferDelegate <NSObject>;

- (void)returnFromDialog:(FileTransferViewController*) fileController;

@end