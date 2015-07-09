/*
 
 Phonegap DatePicker Plugin
 https://github.com/sectore/phonegap3-ios-datepicker-plugin
 
 Based on a previous plugin version by Greg Allen and Sam de Freyssinet.
 Rewrite by Jens Krause (www.websector.de)
 Bugfixes for iPad 8.0 by SNEO
 Bugfixes and changes by koalasafe.com
    - fixed deprecation warnings
    - no more iPad specific functionality, popover caused callback on every spin, no done/cancel button, no obvious way to calc the x/y relative to the input control
    - Using iPhone paradigm on ipad.
 
 MIT Licensed
 
 */

#import "DatePicker.h"
#import <Cordova/CDV.h>

@interface DatePicker ()

@property (nonatomic) UIPopoverController *datePickerPopover;

@property (nonatomic) IBOutlet UIView* datePickerContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *datePickerComponentsContainerVSpace;
@property (nonatomic) IBOutlet UIView* datePickerComponentsContainer;
@property (nonatomic) IBOutlet UIButton *cancelButton;
@property (nonatomic) IBOutlet UIButton *clearButton;
@property (nonatomic) IBOutlet UIButton *doneButton;
@property (nonatomic) IBOutlet UIDatePicker *datePicker;

@end

@implementation DatePicker

#define isIPhone (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define ANIMATION_DURATION 0.3

#pragma mark - UIDatePicker

- (void)show:(CDVInvokedUrlCommand*)command {
    NSMutableDictionary *options = [command argumentAtIndex:0];
    //SNEO - Force the keyboard to hide before anything
    [self.webView endEditing:YES];
    [self showForPhone: options];
}

- (BOOL)showForPhone:(NSMutableDictionary *)options {
    if(!self.datePickerContainer){
        [[NSBundle mainBundle] loadNibNamed:@"DatePicker" owner:self options:nil];
    }
    
    [self updateDatePicker:options];
    [self updateCancelButton:options];
    
    BOOL isClearButton = ([[options objectForKey:@"clearButton"] intValue] == 0) ? NO : YES;
    if (isClearButton) {
        [self updateClearButton:options];
    } else {
        self.clearButton.hidden = YES;
    }
    
    [self updateDoneButton:options];
    
    UIInterfaceOrientation uiInterface = [[UIApplication sharedApplication] statusBarOrientation];
    
    CGFloat width;
    CGFloat height;
    
    if(UIInterfaceOrientationIsLandscape(uiInterface)){
        width = self.webView.superview.frame.size.height;
        height= self.webView.superview.frame.size.width;
    } else {
        width = self.webView.superview.frame.size.width;
        height= self.webView.superview.frame.size.height;
    }
    
    self.datePickerContainer.frame = CGRectMake(0, 0, width, height);
    
    [self.webView.superview addSubview: self.datePickerContainer];
    [self.datePickerContainer layoutIfNeeded];
    
    CGRect frame = self.datePickerComponentsContainer.frame;
    self.datePickerComponentsContainer.frame = CGRectOffset(frame,
                                                            0,
                                                            frame.size.height );
    
    
    self.datePickerContainer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    
    [UIView animateWithDuration:ANIMATION_DURATION
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.datePickerComponentsContainer.frame = frame;
                         self.datePickerContainer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
                         
                     } completion:^(BOOL finished) {
                         
                     }];
    
    return true;
}

- (void)hide {
        CGRect frame = CGRectOffset(self.datePickerComponentsContainer.frame,
                                    0,
                                    self.datePickerComponentsContainer.frame.size.height);
        
        [UIView animateWithDuration:ANIMATION_DURATION
                            delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                            animations:^{
                             self.datePickerComponentsContainer.frame = frame;
                             self.datePickerContainer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
                             
                            } completion:^(BOOL finished) {
                             [self.datePickerContainer removeFromSuperview];
                            }];
    
}

#pragma mark - Actions
- (IBAction)doneAction:(id)sender {
    [self jsDateSelected];
    [self hide];
}

- (IBAction)cancelAction:(id)sender {
    [self hide];
    [self jsDateCancel];
}

- (IBAction)clearAction:(id)sender {
    [self hide];
    [self jsDateClear];
}


- (void)dateChangedAction:(id)sender {
    [self jsDateSelected];
}

#pragma mark - JS API

- (void)jsDateSelected {
    NSTimeInterval seconds = [self.datePicker.date timeIntervalSince1970];
    NSString* jsCallback = [NSString stringWithFormat:@"datePicker._dateSelected(\"%f\");", seconds];
    [self.commandDelegate evalJs:jsCallback];
}

- (void)jsDateClear {
    NSString* jsCallback = [NSString stringWithFormat:@"datePicker._dateSelected(\"clear\");"];
    [self.commandDelegate evalJs:jsCallback];
}

- (void)jsDateCancel {
    NSString* jsCallback = [NSString stringWithFormat:@"datePicker._dateSelected(\"cancel\");"];
    [self.commandDelegate evalJs:jsCallback];
}


#pragma mark - UIPopoverControllerDelegate methods


#pragma mark - Factory methods

- (UIDatePicker *)createDatePicker:(NSMutableDictionary *)options frame:(CGRect)frame {
    UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:frame];
    return datePicker;
}

#define DATETIME_FORMAT @"yyyy-MM-dd'T'HH:mm:ss'Z'"

- (void)updateDatePicker:(NSMutableDictionary *)options {
    NSDateFormatter *formatter = [self createISODateFormatter: DATETIME_FORMAT timezone:[NSTimeZone defaultTimeZone]];
    NSString *mode = [options objectForKey:@"mode"];
    NSString *dateString = [options objectForKey:@"date"];
    BOOL allowOldDates = ([[options objectForKey:@"allowOldDates"] intValue] == 0) ? NO : YES;
    BOOL allowFutureDates = ([[options objectForKey:@"allowFutureDates"] intValue] == 0) ? NO : YES;
    NSString *minDateString = [options objectForKey:@"minDate"];
    NSString *maxDateString = [options objectForKey:@"maxDate"];
    
    if (!allowOldDates) {
        self.datePicker.minimumDate = [NSDate date];
    }
    
    if(minDateString && minDateString.length > 0){
        self.datePicker.minimumDate = [formatter dateFromString:minDateString];
    }
    
    if (!allowFutureDates) {
        self.datePicker.maximumDate = [NSDate date];
    }
    
    if(maxDateString && maxDateString.length > 0){
        self.datePicker.maximumDate = [formatter dateFromString:maxDateString];
    }
    
    self.datePicker.date = [formatter dateFromString:dateString];
    
    if ([mode isEqualToString:@"date"]) {
        self.datePicker.datePickerMode = UIDatePickerModeDate;
    }
    else if ([mode isEqualToString:@"time"]) {
        self.datePicker.datePickerMode = UIDatePickerModeTime;
    } else {
        self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    }
}

- (NSDateFormatter *)createISODateFormatter:(NSString *)format timezone:(NSTimeZone *)timezone {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:timezone];
    [dateFormatter setDateFormat:format];
    
    return dateFormatter;
}

- (void)updateCancelButton:(NSMutableDictionary *)options {
    
    NSString *label = [options objectForKey:@"cancelButtonLabel"];
    [self.cancelButton setTitle:label forState:UIControlStateNormal];
    
    NSString *tintColorHex = [options objectForKey:@"cancelButtonColor"];
    self.cancelButton.tintColor = [self colorFromHexString: tintColorHex];
    
}

- (void)updateClearButton:(NSMutableDictionary *)options {
    
    NSString *label = [options objectForKey:@"clearButtonLabel"];
    [self.clearButton setTitle:label forState:UIControlStateNormal];
    
    NSString *tintColorHex = [options objectForKey:@"clearButtonColor"];
    self.clearButton.tintColor = [self colorFromHexString: tintColorHex];
    
}

- (void)updateDoneButton:(NSMutableDictionary *)options {
    
    NSString *label = [options objectForKey:@"doneButtonLabel"];
    [self.doneButton setTitle:label forState:UIControlStateNormal];
    
    NSString *tintColorHex = [options objectForKey:@"doneButtonColor"];
    [self.doneButton setTintColor: [self colorFromHexString: tintColorHex]];
}


#pragma mark - Utilities

/*! Converts a hex string into UIColor
 It based on http://stackoverflow.com/questions/1560081/how-can-i-create-a-uicolor-from-a-hex-string
 
 @param hexString The hex string which has to be converted
 */
- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

@end