//
//  PMPhotoViewController.m
//  Project Marsara
//
//  Created by Nicolas Langley on 2/22/14.
//  Copyright (c) 2014 hierarchy. All rights reserved.
//

#import "PMSPhotoViewController.h"
#import "PMSImageProcessing.h"

@interface PMSPhotoViewController ()

@end

@implementation PMSPhotoViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Handle case where device has no camera
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:@"Device has no camera"
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles: nil];
        [myAlertView show];
    }
    // Initialize array for item types
    self.itemTypeArray  = [[NSArray alloc] initWithObjects:@"Overwear",@"Shirt",@"Bottom",@"Shoes",nil];
    // Start recommendations button as disabled and hidden
    self.getRecommendations.enabled = NO;
    self.getRecommendations.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
}

# pragma mark - UIButton action handler methods

- (IBAction)takePicture:(UIButton *)sender {
    
    // Create image picker and set source to be camera
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction)selectPicture:(UIButton *)sender {
    // Create image picker and set source to be photo library
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction)getRecommendations:(UIButton *)sender {
    // Get current value of picker
    NSInteger firstRow = [self.itemTypePicker selectedRowInComponent:0];
    NSInteger secondRow = [self.itemTypePicker selectedRowInComponent:1];
    self.fromItemType = [self.itemTypeArray objectAtIndex:firstRow];
    self.toItemType = [self.itemTypeArray objectAtIndex:secondRow];
    
    // Start activity animator animating
    [self.recommendActivityIndicator startAnimating];
    // Run OpenCV calculations in background process
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        // OpenCV calculations for dominant color in image
        cv::Mat src = [PMSImageProcessing cvMatFromUIImage:self.reducedImage];
        cv::Vec3d result = [PMSImageProcessing findDominantColor:src];
        self.TestLabel.text = [NSString stringWithFormat:
                               @"R: %f G: %f B: %f",
                               result[0], result[1], result[2]];
        self.inputColor = [PMSImageProcessing rgbColorToName:result];
        
        // Run backgroundDone function when background process finishes
        dispatch_async(dispatch_get_main_queue(), ^{
            [self backgroundDone];
        });
    });
}

- (void)backgroundDone {
    [self.recommendActivityIndicator stopAnimating];
    [self performSegueWithIdentifier:@"PhotoToResult" sender:self];
}



#pragma mark - Image Picker Controller delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    self.imageView.image = chosenImage;
    self.fromImage = chosenImage;
    
    // Reduce size of image used in image processing
    CGSize reducedSize = {320, 320};
    self.reducedImage = [PMSImageProcessing resizeImage:chosenImage toSize:reducedSize];
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    // Enable get recommendations button
    self.getRecommendations.enabled = YES;
    self.getRecommendations.hidden = NO;
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

#pragma mark - Picker View Data Source methods

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

// returns the # of rows in each component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent: (NSInteger)component {
    return 4;
}

#pragma mark - Picker View delegate methods

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.itemTypeArray objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
}

#pragma mark - Function for handling segue actions

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"PhotoToResult"]){
        PMSResultViewController *controller = (PMSResultViewController *)segue.destinationViewController;
        controller.resultingColour = self.inputColor;
        controller.fromItemType = self.fromItemType;
        controller.toItemType = self.toItemType;
        controller.fromImage = self.fromImage;
    }
}

@end
