/*
 *  QRController.h
 *  
 *
 *  Created by Gaurav Khanna on 11/28/09.
 *  Copyright 2009 xShad0w. All rights reserved.
 *
 */

#import <UIKit/UIKit.h>
#import "QRView.h"

@interface QRService : NSObject {
    
}

+ (void)displayWithCKMessage:(CKMessage *)message; //automatically detect orientation and set accordingly

+ (void)displayWithCKMessage:(CKMessage *)message orientation:(UIInterfaceOrientation)orientation;

//+ (void)_displayWithCKMessage:(CKMessage *)message;
/*- (void)_initWithCKMessage:(CKMessage *)message;
- (void)_initWithCKMessage:(CKMessage *)message orientation:(UIInterfaceOrientation)initOrientation;*/

@end