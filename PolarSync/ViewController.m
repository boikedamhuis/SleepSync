//
//  ViewController.m
//  PolarSync
//
//  Created by Rutger Nijhuis on 21/10/15.
//  Copyright © 2015 Rutger Nijhuis. All rights reserved.
//

#import "ViewController.h"
#import "RRDownloader.h"
@import HealthKit;

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loader;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(DidStartDownload) name:@"start" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didEndDownload) name:@"end" object:nil];
    
    
    //Set fonts
    _bedTimeLabel.font = [UIFont fontWithName:@"FSAlbert-ExtraBold" size:28];
    _goalLabel.font = [UIFont fontWithName:@"FSAlbert-ExtraBold" size:90];
    _quoteLabel.font = [UIFont fontWithName:@"FSAlbert-ExtraBold" size:17];
    _lastSyncedLabel.font = [UIFont fontWithName:@"FSAlbert-ExtraBold" size:12];
    
    //Set last synced date
    _lastSyncedLabel.text = [NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults]objectForKey:@"lastSyncedDate"]];
    
    
    //Calculate goal
    double currentSleep = [[NSUserDefaults standardUserDefaults] doubleForKey:@"sleepTime"];
    NSLog(@"%f", currentSleep);
    
    float goal = currentSleep / 28800 * 100;
    NSString *goalString = [NSString stringWithFormat:@"%.0f", goal];
    _goalLabel.text = [NSString stringWithFormat:@"%@%%", goalString];
    [self checkSucceededWithGoal:goal];
    
    

    
}

-(void)viewDidAppear:(BOOL)animated{
    HKHealthStore *store = [HKHealthStore new];
    
    HKObjectType *sleep = [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    
    switch ([store authorizationStatusForType:sleep]) {
        case HKAuthorizationStatusNotDetermined:{
            // Requesting stuff
            [store requestAuthorizationToShareTypes:[NSSet setWithArray:@[sleep]]
                                          readTypes:[NSSet setWithArray:@[sleep]]
                                         completion:^(BOOL success, NSError * _Nullable error) {
                                             dispatch_sync(dispatch_get_main_queue(), ^{
                                                 [[RRDownloader downloader]syncSleep];                                                 
                                             });

                                         }];
        }
            
            break;
        case HKAuthorizationStatusSharingAuthorized:
            // We're good
            [[RRDownloader downloader]syncSleep];
            break;
        case HKAuthorizationStatusSharingDenied:{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sukkel" message:@"Je hebt fucking permissions denied" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok= [UIAlertAction actionWithTitle:@"Ik ben een sukkel" style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:ok];
            [self showViewController:alert sender:self];
        }
            break;
    }
}


-(void)DidStartDownload{
    [self.loader startAnimating];
}
-(void)didEndDownload{
    [self.loader stopAnimating];
    
    //Create a timelabel
    NSDate *currentTime = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd'-'MM''HH':'mm':'ss'"];
    NSString *date = [dateFormatter stringFromDate: currentTime];
    NSString *resultString = [NSString stringWithFormat:@"Last synced: %@", date];
    _lastSyncedLabel.text = [NSString stringWithFormat:@"%@", resultString];
    
    //Store data
    [[NSUserDefaults standardUserDefaults] setObject:resultString forKey:@"lastSyncedDate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    double currentSleep = [[NSUserDefaults standardUserDefaults] doubleForKey:@"sleepTime"];
    NSLog(@"%f", currentSleep);
    
    float goal = currentSleep / 32400 * 100;
    NSString *goalString = [NSString stringWithFormat:@"%.0f", goal];
    _goalLabel.text = [NSString stringWithFormat:@"%@%%", goalString];

    
    
    sleepNeeded = 32400 - currentSleep;
    NSLog(@"%f", sleepNeeded);
    
    [self checkSucceededWithGoal:goal];
}
-(void)checkSucceededWithGoal:(float)goal {
    
    if (goal > (float)99.999) {
        NSLog(@"Goal reached");
        _goalLabel.font = [UIFont fontWithName:@"FSAlbert-ExtraBold" size:70];
        _goalLabel.text = @"Reached!";
        _quoteLabel.hidden = YES;
        _bedTimeLabel.hidden = YES;

    } else {
        _quoteLabel.hidden = NO;
        _bedTimeLabel.hidden = NO;
        
       // NSLog(@"%f", sleepNeeded);
        
        
        //get sleep needed
        
        int sleep = (int) sleepNeeded;
        int seconds = sleep % 60;
        int minutes = (sleep / 60) % 60;
        int hours = sleep / 3600;
        

        //Convert to bedtime
        int remainingSeconds = 60 - seconds;
        int remainingMinutes = 60 - minutes;
        int remainingHours = 23 - hours;

    
        NSString *time = [NSString stringWithFormat:@"%02d:%02d",remainingHours, remainingMinutes];
        
        
        
        //Set text
        _quoteLabel.numberOfLines = 2;
        _quoteLabel.text = [NSString stringWithFormat:@"x hours and y minutes of sleep \n last night"];
        
                
    }
    
}

@end
