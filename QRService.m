/*
 *  QRController.mm -- QRController Class implementation
 *  
 *
 *  Created by Gaurav Khanna on 02/01/09.
 *  Copyright 2009 xShad0w. All rights reserved.
 *  Contact: Gauravk92@gmail.com
 *
 *  This file is part of iphone-quickreply or QuickReply.
 */

#import "QRService.h"

@implementation QRService

+ (void)displayWithCKMessage:(CKMessage *)message {
    if([QRController checkAddressInInstances:[message address]])
        [[QRController viewForAddressInInstances:[message address]] addMessage:message animated:true];
    else
        [[QRView alloc] _initWithCKMessage:message];
}

+ (void)_displayWithCKMessage:(CKMessage *)message orientation:(UIInterfaceOrientation)orientation{
    [[QRView alloc] _initWithCKMessage:message orientation:orientation];
}

+ (void)_displayWithCKMessage:(CKMessage *)message {
    [[QRView alloc] _initWithCKMessage:message];
}

/*- (void)_initWithCKMessage:(CKMessage *)message {
    [[QRView alloc] _initWithCKMessage:message orientation:UIInterfaceOrientationPortrait];
}*/


@end