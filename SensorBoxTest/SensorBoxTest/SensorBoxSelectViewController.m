//
//  SensorBoxSelectViewController.m
//  SensorBoxTest
//
//  Created by Marc Andre on 4/12/12.
//  Copyright (c) 2012 Aïmago SA. All rights reserved.
//

#import "SensorBoxSelectViewController.h"


@implementation SensorBoxSelectViewController 

@synthesize delegate;
@synthesize pickerView;
@synthesize sensorBoxes;
@synthesize selectedSensorBox;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)dealloc
{
    self.sensorBoxes = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.selectedSensorBox = [self.sensorBoxes objectAtIndex:0];
}

- (void)viewDidUnload
{
    [self setPickerView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (IBAction)buttonOkPush:(id)sender 
{
    [[self delegate] selectDoneViewController:self selectedSensorBox:self.selectedSensorBox];
}

- (IBAction)buttonCancelPush:(id)sender 
{
    [[self delegate] selectDoneViewController:self selectedSensorBox:nil];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.sensorBoxes.count;
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[self.sensorBoxes objectAtIndex:row] deviceName];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.selectedSensorBox = [self.sensorBoxes objectAtIndex:row];
}

@end
