//
//  RRDownloader.m
//  PolarSync
//
//  Created by Rutger Nijhuis on 21/10/15.
//  Copyright © 2015 Rutger Nijhuis. All rights reserved.
//

#import "RRDownloader.h"
#import "AFNetworking.h"
#import "TFHpple.h"

@import HealthKit;

static RRDownloader *sharedDownloader = nil;


@interface RRDownloader ()<UIWebViewDelegate>{
    UIWebView *webview;
    AFHTTPSessionManager *manager;
    
    NSString *sleepURL;
}

@end

@implementation RRDownloader


#pragma mark - Initializers

-(instancetype)init{
    self = [super init];
    
    manager = [[AFHTTPSessionManager alloc]init];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    return self;
}

+(RRDownloader *)downloader{
    @synchronized(self) {
        if (sharedDownloader) return sharedDownloader;
        
        static dispatch_once_t pred;
        dispatch_once(&pred, ^{
            sharedDownloader = [RRDownloader new];
        });
    }
    return sharedDownloader;
}


#pragma mark - Sync methods

-(void)syncSleep{
    [self createPolarSession];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"start" object:nil];
}

-(void)createPolarSession{
    webview = [UIWebView new];
    webview.delegate = self;
    
    
    NSDateFormatter *fm = [[NSDateFormatter alloc]init];
    [fm setDateFormat:@"d.M.YYYY"];
    
    NSString *dateFrom = [fm stringFromDate:[[NSDate date] dateByAddingTimeInterval:-(60*60*24*30*6)]]; // 6 months back
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"lastSync"]) {
        dateFrom = [fm stringFromDate:[[[NSUserDefaults standardUserDefaults]objectForKey:@"lastSync"] dateByAddingTimeInterval:-(60*60*24)]]; // day before last sync day
    }
    
    NSString *dateUntill = [fm stringFromDate:[NSDate date]];
    
    sleepURL = [NSString stringWithFormat:@"https://flow.polar.com/activity/data/%@/%@?_=%f",dateFrom,dateUntill,[[NSDate date] timeIntervalSince1970]*1000]; // json page
    sleepURL = [NSString stringWithFormat:@"https://flow.polar.com/training/day/%@/%@/day",[fm stringFromDate:[NSDate date]],[fm stringFromDate:[NSDate date]]]; // html page
    summaryURL =[NSString stringWithFormat:@"https://flow.polar.com/activity/summary/%@/%@/day",[fm stringFromDate:[NSDate date]],[fm stringFromDate:[NSDate date]]]; // html page
    
    
    NSDictionary *params = @{@"email" : @"boike.damhuis@me.com",
                             @"password" : @"polarflowapp123",
                             @"returnUrl" : @"https://flow.polar.com/"
                             };
    
    [manager POST:@"https://flow.polar.com/login"
       parameters:params
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
              
              NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:nil];
              NSLog(@"Success:%@",response);
              
              // Request page in webview
              [webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:sleepURL]]];
              
          } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
              NSLog(@"fail: %@",error.description);
          }];
}

-(void)loadPolarData{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", summaryURL]];
    NSData *htmlDataFromUrl = [NSData dataWithContentsOfURL:url];
    TFHpple *parser = [TFHpple hppleWithHTMLData:htmlDataFromUrl];
    NSString *xPath = @"//body/div/div/div/div[6]/span[1]";
    NSArray *nodes = [parser searchWithXPathQuery:xPath];
    NSMutableArray *data = [[NSMutableArray alloc] initWithCapacity:0];
    for (TFHppleElement *element in nodes) {
        NSLog(@"%@",[[element firstChild] content]);
        //start converting the string
        NSString *fullSummary = [[element firstChild] content];
        NSRange range = [fullSummary rangeOfString:@" "];
        
        int rangeInt;
        if (range.location == NSNotFound) {
                    }
        
        else {
            
            rangeInt = range.location;
            NSMutableString *mu = [NSMutableString stringWithString:fullSummary];
            [mu insertString:@":" atIndex:rangeInt];
            [mu insertString:@"0" atIndex:0];
            NSString *withoutSpaces = [mu stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSString* cleanedString = [withoutSpaces stringByTrimmingCharactersInSet: [NSCharacterSet letterCharacterSet]];

            NSString* finished =
            [[cleanedString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ"]]
             componentsJoinedByString:@""];
            NSLog(@"CLEANED: %@", finished);
        }
        

    }
    

    
    
    
}




#pragma mark - UIWebiewDelegate

-(void)webViewDidStartLoad:(UIWebView *)webView{
    NSLog(@"DidStartLoad:");
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    NSLog(@"DidEndLoad:");
    [self loadPolarData];
}


#pragma mark - HealthKit

-(void)processDataInHealthKit:(NSArray*)data{
    HKHealthStore *store = [HKHealthStore new];
    HKCategoryType *typ = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    NSTimeInterval timeZoneFix = [[NSTimeZone defaultTimeZone]secondsFromGMT];
    
    for (NSDictionary *dayData in data) {
        NSTimeInterval sleepTime = [dayData[@"summaries"][0][@"sleepTime"]doubleValue]/1000;
        NSTimeInterval startTimeInterval = ([dayData[@"summaries"][0][@"startTime"]doubleValue]/1000)-timeZoneFix;

        NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:startTimeInterval];
        NSLog(@"Sleeptime:%.0f",sleepTime);
        
        [[NSUserDefaults standardUserDefaults] setDouble:[dayData[@"summaries"][0][@"sleepTime"]doubleValue]/1000 forKey:@"sleepTime"];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        if (sleepTime == 0.) {
            NSLog(@"No sleep data available..");
            continue;
        }
        
        NSDate *endDate = [startDate dateByAddingTimeInterval:sleepTime];
        
        NSLog(@"Start:%@\nEnd:%@",startDate,endDate);
        
        // Now real shit happens
        
        HKCategorySample *object = [HKCategorySample categorySampleWithType:typ value:HKCategoryValueSleepAnalysisAsleep startDate:startDate endDate:endDate];
        NSPredicate *perdicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
        
        // Delete previous sleeps
        [store deleteObjectsOfType:typ
                         predicate:perdicate
                    withCompletion:^(BOOL success, NSUInteger deletedObjectCount, NSError * _Nullable error) {
//                        NSLog(@"Deleted %lu items",deletedObjectCount);
                    }];
        
        // Save new data
        [store saveObject:object withCompletion:^(BOOL success, NSError * _Nullable error) {
            if (error) {
                NSLog(@"%@",error.description);
                return;
            }
            
            if (success) {
//                NSLog(@"Saved sleep!");
            }
            else{
                NSLog(@"Wow, something else went wrong!!");
            }
        }];
    }
    //Store sleeptime
   
    
    UILocalNotification *not = [[UILocalNotification alloc]init];
    not.fireDate = [NSDate date];
    not.alertBody = @"Sleep is gesynced 😘";
    not.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:not];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"end" object:nil];
    
    [[NSUserDefaults standardUserDefaults]setObject:[NSDate date] forKey:@"lastSync"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

@end
