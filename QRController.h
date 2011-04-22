/*
 *  QRController.h
 *  
 *
 *  Created by Gaurav Khanna on 11/28/09.
 *  Copyright 2009 xShad0w. All rights reserved.
 *
 */

#import <UIKit/UIKit.h>
#import <singleton.h>

#import "QRView.h"

@class QRView;

@interface QRController : NSObject {
    NSMutableDictionary *_instances;
}

+ (QRController *)sharedController;
- (id)instances;
- (BOOL)hasActiveInstance;
- (BOOL)checkAddressInInstances:(NSString *)address;
- (QRView *)viewForAddressInInstances:(NSString *)address;
- (void)addAddressInInstances:(NSString *)address object:(QRView *)object;
- (void)removeAddressInInstances:(NSString *)address object:(QRView *)object;

@end