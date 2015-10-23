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

#define EMAIL @"email@here.com"
#define PASSWORD @"PasswordHere"


@import HealthKit;

static RRDownloader *sharedDownloader = nil;


@interface RRDownloader ()<UIWebViewDelegate>{
    UIWebView *webview;
    AFHTTPSessionManager *manager;
    
    NSString *sleepURL;
    
    NSDate *sleepDate;
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
    
    
    fm = [[NSDateFormatter alloc]init];
    [fm setDateFormat:@"d.M.YYYY"];
    
    
    sleepDate = [[NSDate date] dateByAddingTimeInterval:0]; // Yesterday
    sleepDate = [[NSCalendar currentCalendar] dateFromComponents:[[NSCalendar currentCalendar] components:(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:sleepDate]]; // Yesterday at 00:00 in current timezone
    
    sleepURL = [NSString stringWithFormat:@"https://flow.polar.com/activity/summary/%@/%@/day",[fm stringFromDate:sleepDate],[fm stringFromDate:sleepDate]];
    
    NSDictionary *params = @{@"email" : EMAIL,
                             @"password" : PASSWORD,
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
    
    [manager GET:sleepURL parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
        TFHpple *parser = [TFHpple hppleWithData:responseObject isXML:NO];
        NSString *xPath = @"//body/div/div/div/div[6]/span[1]";
        NSArray *nodes = [parser searchWithXPathQuery:xPath];
       
        if ([nodes firstObject]) {
            TFHppleElement *element = [[nodes firstObject] firstChild];
            NSLog(@"%@", [element content]);
            
            NSString *fullSummary = [element content];
            NSRange range = [fullSummary rangeOfString:@" "];
            NSString *finished;
            int rangeInt;
            if (range.location == NSNotFound) {
                
            } else {
                rangeInt = range.location;
                NSMutableString *mu = [NSMutableString stringWithString:fullSummary];
                [mu insertString:@":" atIndex:rangeInt];
                
                NSString *withoutSpaces = [mu stringByReplacingOccurrencesOfString:@" " withString:@""];
                NSString *cleanedString = [withoutSpaces stringByTrimmingCharactersInSet:[NSCharacterSet letterCharacterSet]];
                
                finished = [[cleanedString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghilklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"]] componentsJoinedByString:@""];
                NSLog(@"%@", finished);
                
            }
            
            NSDateFormatter *fmElement = [NSDateFormatter new];
            [fmElement setDateFormat:@"H':'m'"];
            
            NSDate *formattedDate = [fmElement dateFromString:finished];
            
            NSCalendar *cal = [NSCalendar currentCalendar];
            
            NSDateComponents *comps=[cal components:(NSCalendarUnitHour|NSCalendarUnitMinute) fromDate:formattedDate];
            
            int hours = (int)[comps hour];
            int minutes = (int)[comps minute];
            
            NSDate *wakeUpDate = [sleepDate dateByAddingTimeInterval:hours*60*60+minutes*60];
            [self processDataInHealthKitWithSleepDate:sleepDate wakeDate:wakeUpDate];
            
        }
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        NSLog(@"Failed to load url:%@\n%@",sleepURL,error.description);
    }];
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

-(void)processDataInHealthKitWithSleepDate:(NSDate*)startDate wakeDate:(NSDate*)wakeDate{
    HKHealthStore *store = [HKHealthStore new];
    HKCategoryType *typ = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    
        // Now real shit happens
        
        HKCategorySample *object = [HKCategorySample categorySampleWithType:typ value:HKCategoryValueSleepAnalysisAsleep startDate:startDate endDate:wakeDate];
        NSPredicate *perdicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:wakeDate options:HKQueryOptionStrictStartDate];
        
        // Delete previous sleeps
        [store deleteObjectsOfType:typ
                         predicate:perdicate
                    withCompletion:^(BOOL success, NSUInteger deletedObjectCount, NSError * _Nullable error) {
                        NSLog(@"Deleted %lu items",deletedObjectCount);
                    }];
        
        // Save new data
        [store saveObject:object withCompletion:^(BOOL success, NSError * _Nullable error) {
            if (error) {
                NSLog(@"%@",error.description);
                return;
            }
            
            if (success) {
                NSLog(@"Saved sleep!");
            }
            else{
                NSLog(@"Wow, something else went wrong!!");
            }
        }];
    
    //Store sleeptime
   
    
    
    [[NSUserDefaults standardUserDefaults]setObject:[NSDate date] forKey:@"lastSync"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

@end
