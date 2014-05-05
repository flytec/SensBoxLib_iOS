//
//  SensorBoxSelectViewController.h
//  SensorBoxTest
//
//  Created by Marc Andre on 4/12/12.
//  Copyright (c) 2012 Aïmago SA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SensorBoxLib.h"

@protocol SensorBoxSelectDelegate;


@interface SensorBoxSelectViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (assign, nonatomic) id <SensorBoxSelectDelegate> delegate;
@property (assign, nonatomic) IBOutlet UIPickerView *pickerView;
@property (retain, nonatomic) NSArray* sensorBoxes;
@property (assign, nonatomic) SensorBox* selectedSensorBox;

- (IBAction)buttonOkPush:(id)sender;
- (IBAction)buttonCancelPush:(id)sender;

@end


@protocol SensorBoxSelectDelegate <NSObject>;

- (void)selectDoneViewController:(SensorBoxSelectViewController*) selectController
               selectedSensorBox:(SensorBox*)sensorBox;

@end