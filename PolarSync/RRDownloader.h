//
//  RRDownloader.h
//  PolarSync
//
//  Created by Rutger Nijhuis on 21/10/15.
//  Copyright © 2015 Rutger Nijhuis. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RRDownloader : NSObject

+(RRDownloader*)downloader;


-(void)syncSleep;
@end
