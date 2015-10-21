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
                                             [[RRDownloader downloader]syncSleep];
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
}

@end
