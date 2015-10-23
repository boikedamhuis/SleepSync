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
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Ooeps!" message:@"Health permissions denied!" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok= [UIAlertAction actionWithTitle:@"Okay!" style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:ok];
            [self showViewController:alert sender:self];
        }
            break;
    }
}


-(void)DidStartDownload{
    //Create a timelabel
    NSDate *currentTime = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd'-'MM''HH':'mm':'ss'"];
    NSString *date = [dateFormatter stringFromDate: currentTime];
    NSString *resultString = [NSString stringWithFormat:@"Last synced: %@", date];
    _lastSyncedLabel.text = [NSString stringWithFormat:@"%@", resultString];
}
-(void)didEndDownload{
    
    //Create a timelabel
    NSDate *currentTime = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd'-'MM''HH':'mm':'ss'"];
    NSString *date = [dateFormatter stringFromDate: currentTime];
    NSString *resultString = [NSString stringWithFormat:@"Last synced: %@", date];
    _lastSyncedLabel.text = [NSString stringWithFormat:@"%@", resultString];

    
    
   

}

@end
