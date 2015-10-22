//
//  ViewController.h
//  PolarSync
//
//  Created by Rutger Nijhuis on 21/10/15.
//  Copyright © 2015 Rutger Nijhuis. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController {
    float sleepNeeded;
}
@property (weak, nonatomic) IBOutlet UILabel *bedTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *goalLabel;
@property (weak, nonatomic) IBOutlet UILabel *quoteLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastSyncedLabel;
-(void)checkSucceededWithGoal:(float)goal;

@end

