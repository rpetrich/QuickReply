/*
 *  QuickReply.h
 *  
 *
 *  Created by Gaurav Khanna on 10/5/09.
 *  Copyright 2009 Khanna Enterprises Inc.. All rights reserved.
 *
 */

@interface QRView : UIView {
    
}
// Checks if existing quickreply window exists with same message address, if so adds to window otherwise sets up new window
+ (void)displayWithCKMessage:(CKMessage *)message; 
// Creates new window using input orientation, default is UIInterfaceOrientationPortrait (doesnt check for existing window)
+ (void)_displayWithCKMessage:(CKMessage *)message orientation:(UIInterfaceOrientation)orientation;




@end

/* Example Usage
 *
 * CKMessage *exampleCKMessage;
 *
 *    [QRView displayWithCKMessage:exampleCKMessage];
 *
 *
 */

