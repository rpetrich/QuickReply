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

#import "QRController.h"

@implementation QRController

MAKE_SINGLETON(QRController, sharedController)

- (id)instances {
    return _instances;
}

- (BOOL)hasActiveInstance {
    if([_instances count] > 0)
        return TRUE;
    return FALSE;
}

- (BOOL)checkAddressInInstances:(NSString *)address {
    if([_instances objectForKey:address])
        return TRUE;
    else
        return FALSE;
}

- (QRView *)viewForAddressInInstances:(NSString *)address {
    return [[_instances objectForKey:address] pointerValue];
}

- (void)addAddressInInstances:(NSString *)address object:(QRView *)object {
    [_instances setObject:[[NSValue alloc] initWithBytes:&object objCType:@encode(void *)] forKey:address];
}

- (void)removeAddressInInstances:(NSString *)address object:(QRView *)object {
    [_instances removeObjectForKey:address];
}

@end