/*
 *  QRLibrary.mm -- Implementation code, when/where/how QuickReply will be activated and change original SMS Alert
 *  
 *
 *  Created by Gaurav Khanna on 02/01/09.
 *  Copyright 2009 xShad0w. All rights reserved.
 *  Contact: Gauravk92@gmail.com
 *
 *  This file is part of iphone-quickreply or QuickReply.
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <GraphicsServices/GraphicsServices.h>
#import <AddressBook/AddressBook.h>
#import <QuartzCore/QuartzCore.h>
#import <SpringBoard/SpringBoard.h>
#import <ChatKit/ChatKit.h>
#include "DRM.h"

#import <CaptainHook/CaptainHook.h>

//#define DEBUG
//#define BETA
//#define TESTING
//#define DLOG

#ifdef DEBUG
//#import "QRLibraryDebug.mm"
#endif

CHDeclareClass(SBSMSAlertItem);
CHDeclareClass(SBAlertItemsController);
CHDeclareClass(SMSAlertSheet);
CHDeclareClass(SBAwayController);
CHDeclareClass(SBUIController);
CHDeclareClass(SpringBoard);
CHDeclareClass(SBAwayItemsView);
CHDeclareClass(CKSMSService);

#import "QRView.h"
#import "QRWindow.h"
#import "QRController.h"

@class QRView, QRWindow, QRController;

#pragma mark MS Hooks

CHMethod(2, void, SBSMSAlertItem, configure, BOOL, configure, requirePasscodeForActions, BOOL, require) {
    CHSuper(2, SBSMSAlertItem, configure, configure, requirePasscodeForActions, require);
    UIModalView *sheet = nil;
    UIAlertView *oSheet = [self alertSheet];
    if([oSheet numberOfButtons] > 0) {
        sheet = [[UIModalView alloc] initWithTitle:[oSheet title]
                                           message:[oSheet message]
                                          delegate:self
                                     defaultButton:nil
                                      cancelButton:nil
                                      otherButtons:nil];
        [sheet addButtonWithTitle:[oSheet buttonTitleAtIndex:0]];
        [sheet addButtonWithTitle:NSLocalStringSB( ( (PREF(@"CallButton") && ![[$(SBTelephonyManager) sharedTelephonyManager] inCall]) 
                                                    ? @"CALL_PERMISSION_ALERT_CALL" 
                                                    : @"VIEW" )
                                                  )];
        [sheet addButtonWithTitle:NSLocalStringSB(@"REPLY")];
        [sheet setNumberOfRows:1];
        [sheet setCancelButtonIndex:0];
        [sheet setDefaultButtonIndex:2];
        [oSheet release];
        oSheet = nil;
        object_setInstanceVariable(self, "_alertSheet", (void **)sheet);
    }
    sheet = [self alertSheet];
    
    if(IS_DEVELOPER_DEVICE){
       if([[$(SBAwayController) sharedAwayController] isLocked]){
           [CHIvar(sheet, _bodyTextLabel, UILabel *) setTextAlignment:UITextAlignmentCenter];
           [sheet setMessage:@"Text Message"];
           object_setInstanceVariable(self, "_displayingEntireMessage",(void **)true);
           for(id anObject in sheet.subviews) {
               if([anObject isKindOfClass:$(UIImageView)] || [anObject isKindOfClass:$(MMSBevelView)]){
                   [anObject removeFromSuperview];
               }
           }
       }
    }
    sheet = nil;
}


CHMethod(2, void, SBSMSAlertItem, alertSheet, id, sheet, buttonClicked, int, button) {
    [self dismiss];
    switch (button) {
        case 1:
            if(CHIvar(self, _displayingEntireMessage, BOOL)) {
                CKMessage *msg = CHIvar(self, _message, CKMessage *);
                MARK_MESSAGE_READ(msg)
            }
            break;
        case 2:
            if (PREF(@"CallButton") && ![[$(SBTelephonyManager) sharedTelephonyManager] inCall])
                [[$(SpringBoard) sharedApplication] applicationOpenURL:[NSURL URLWithString:[@"tel://" stringByAppendingString:[self address]]]];
            else
                [self reply];
            break;
        case 3:
            [QRView _displayWithCKMessage:CHIvar(self, _message, CKMessage *)
                              orientation:[QRWindow convertModeToInterfaceOrientation:[sheet _currentOrientation]]];
            break;
    }
}

CHMethod(1, void, SBAlertItemsController, activateAlertItem, id, alertItem) {
    if([alertItem isKindOfClass:$(SBSMSAlertItem)] && [[QRController sharedController] checkAddressInInstances:[alertItem address]]){
#ifdef TESTING
        //QRView *_view = [QRView displayWithSBSMSAlertItem:alertItem]; //immediatly display quickreply without alert
        _SBAlertItemsController$activateAlertItem$(self,sel,alertItem); //override to display alert despite existing QR view
#else
        DLogINT([[alertItem alertSheet] numberOfRows]);
        QRView *view = [[QRController sharedController] viewForAddressInInstances:[alertItem address]];
        [view addMessage:CHIvar(alertItem, _message, CKMessage *) animated:true];
        if([[$(SBAwayController) sharedAwayController] isLocked]){
            NSMutableArray *smsArray = CHIvar([[$(SBAwayController) sharedAwayController] awayModel], _SMSs, id);
            [smsArray removeObject:CHIvar(alertItem, _message, CKMessage *)];
        }
#endif
#ifdef IPHONE_OS_4
        DLogFunc();
        [CLASS(SBSMSAlertItem) playMessageReceived];
#else
        [alertItem willPresentAlertSheet:nil];
#endif
    }else if ([alertItem isKindOfClass:$(SBSMSAlertItem)] && ![[$(SBAwayController) sharedAwayController] isLocked]) {
        [CLASS(SBSMSAlertItem) playMessageReceived];
        CHSuper(1, SBAlertItemsController, activateAlertItem, alertItem);
    }else
        CHSuper(1, SBAlertItemsController, activateAlertItem, alertItem);

}

CHMethod(0, BOOL, SBUIController, clickedMenuButton) {
    if(QR_IS_ACTIVE) {
        [[QRWindow sharedWindow] resignKeyWindowAnimated];
        return true;
    } else
        return CHSuper(0, SBUIController, clickedMenuButton);
}

CHMethod(0, void, SBAwayController, dimTimerFired) {
    if(!(QR_IS_ACTIVE))
        CHSuper(0, SBAwayController, dimTimerFired);
}

CHMethod(1, void, CKSMSService, _sendError, CKSMSRecordRef, rec) {
    CHSuper(1, CKSMSService, _sendError, rec);
#ifdef BETA
    //Add some code here to try a resend in the future
#else
    SBDismissOnlyAlertItem *alert = [[$(SBDismissOnlyAlertItem) alloc] initWithTitle:NSLocalStringCK(@"FAILED_SUMMARY") body:@""];
    [(SBAlertItemsController*)[$(SBAlertItemsController) sharedInstance] activateAlertItem:alert];
    [alert release];
#endif
}

CHMethod(1, CGSize, SMSAlertSheet, sizeThatFits, CGSize, size) {
    size = CHSuper(1, SMSAlertSheet, sizeThatFits, size); //_SMSAlertSheet$sizeThatFits$(self,sel,size);
    if(PREF(@"ContactPicture") && [self viewWithTag:77]) // 77 = QR on numpad
        size.height += 32.0;
    return size;
}

CHMethod(0, void, SMSAlertSheet, layoutSubviews) {
    CHSuper(0, SMSAlertSheet, layoutSubviews);
    DLogINT([self numberOfRows]);
    if(PREF(@"ContactPicture") && (![self viewWithTag:77])) {
        int uid = [[[CHIvar([self delegate], _message, CKMessage *) conversation] recipient] addressBookUID];
        if(uid != -1){
            ABAddressBookRef addressBook = ABAddressBookCreate();
            ABRecordRef record = ABAddressBookGetPersonWithRecordID(addressBook, uid);
            DLogCFRetain(record);
            CFRetain(record);
            if(ABPersonHasImageData(record)){
                UILabel *titleLabel = CHIvar(self, _titleLabel, UILabel *);
                for(id anSubview in self.subviews) {
                    if(![anSubview isEqual:titleLabel]){
                       CGPoint center = [anSubview center];
                       center.y += 32.0;
                       [anSubview setCenter:center];
                    }
                }
                
                CGRect frame = [titleLabel frame];
                frame.size.width -= 75.0;
                [titleLabel setFrame:frame];
                titleLabel.textAlignment = UITextAlignmentLeft;
                
                CFDataRef data = ABPersonCopyImageData(record);
                UIImage *img = [[UIImage alloc] initWithData:(NSData*)data];
                CFRelease(data);
                UIImageView *view = [[UIImageView alloc] initWithImage:img];
                view.tag = 77; // 77 = QR on numpad
                [img release];
                [view setFrame:CGRectMake(205.0, frame.origin.y, 55.0, 55.0)];
                view.layer.cornerRadius = 5.0;
                view.layer.masksToBounds = YES;
                view.layer.borderColor = [UIColor colorWithWhite:0.0 alpha:0.8].CGColor;
                view.layer.borderWidth = 1.0;
                
                [self addSubview:view];
                [view release];
                [self sizeToFit];
            }
            CFRelease(record);
            CFRelease(addressBook);
        }
    }
}

CHMethod(0, void, SBAwayController, smsMessageReceived) {
    CHSuper(0, SBAwayController, smsMessageReceived);
    if(IS_DEVELOPER_DEVICE)
        [self cleansePendingQueueOfAwayItems];
}

#define HORIZ_SWIPE_DRAG_MIN 35
#define VERT_SWIPE_DRAG_MAX 4
static CGPoint startTouchPosition;
CHMethod(2, void, SMSAlertSheet, touchesBegan, NSSet *, touches, withEvent, UIEvent *, event) {
    CHSuper(2, SMSAlertSheet, touchesBegan, touches, withEvent, event);
    startTouchPosition = [[touches anyObject] locationInView:self];
}

CHMethod(2, void, SMSAlertSheet, touchesMoved, NSSet *, touches, withEvent, UIEvent *, event) {
    CHSuper(2, SMSAlertSheet, touchesMoved, touches, withEvent, event);
    CGPoint currentTouchPosition = [[touches anyObject] locationInView:self];
    if (fabsf(startTouchPosition.x - currentTouchPosition.x) >= HORIZ_SWIPE_DRAG_MIN && 
        fabsf(startTouchPosition.y - currentTouchPosition.y) <= VERT_SWIPE_DRAG_MAX) {
        [self dismissAnimated:false];
        if(CHIvar([self delegate], _displayingEntireMessage, BOOL)) {
            CKMessage *msg = CHIvar([self delegate], _message, CKMessage *);
            MARK_MESSAGE_READ(msg);
        }
    }
}

CHMethod(2, void, SMSAlertSheet, touchesEnded, NSSet *, touches, withEvent, UIEvent *, event) {
    CHSuper(2, SMSAlertSheet, touchesEnded, touches, withEvent, event);
    if (PREF(@"ShowOnLockScreen") && [[touches anyObject] tapCount] == 2) {
        CKMessage *msg = CHIvar([self delegate], _message, CKMessage *);
        [self dismissAnimated:false];
        SBAwayController *sbAwayController = [$(SBAwayController) sharedAwayController];
        NSMutableArray *smsArray = CHIvar([sbAwayController awayModel], _SMSs, id);
        [smsArray removeObject:msg];
        [sbAwayController cancelDimTimer];
        [sbAwayController performSelector:@selector(cancelDimTimer) withObject:nil afterDelay:1.0];
        [QRView displayWithCKMessage:msg];
        [sbAwayController cancelScheduledSMSSounds];
    }
}

#ifndef IPHONE_OS_4
CHMethod(2, void, SBAwayItemsView, touchesEnded, NSSet *, touches, withEvent, UIEvent *, event) {
    CHSuper(2, SBAwayItemsView, touchesEnded, touches, withEvent, event);
    if (PREF(@"ShowOnLockScreen") && [[touches anyObject] tapCount] == 2) {
        SBAwayController *sbAwayController = [$(SBAwayController) sharedAwayController];
        NSArray *displayedItems = CHIvar(self, _displayedItems, NSArray *);
        //  _displayedItems contains <SBAwayItem>'s, SBAwayItem types - 0:SMS 1:CALL
        if([displayedItems count] == 1){
            NSMutableArray *smsArray = CHIvar([sbAwayController awayModel], _SMSs, NSMutableArray *);
            if([smsArray count] > 0) {
                [self dismissAnimated:false];
                [sbAwayController cancelDimTimer];
                [sbAwayController performSelector:@selector(cancelDimTimer) withObject:nil afterDelay:1.0];
                [sbAwayController cancelScheduledSMSSounds];
                [QRView _displayWithCKMessage:[smsArray objectAtIndex:0]];
                NSString *address = [[smsArray objectAtIndex:0] address];
                [smsArray removeObjectAtIndex:0];
                if([smsArray count] > 0) {
                    QRView *view = [[QRController sharedController] viewForAddressInInstances:address];
                    while ([smsArray count] > 0) {
                        [view addMessage:[smsArray objectAtIndex:0] animated:false];
                        [smsArray removeObjectAtIndex:0];
                    }
                }
            }
            NSMutableArray *callsArray = CHIvar([sbAwayController awayModel], _calls, NSMutableArray *);
            if([callsArray count] > 0) {
                [self dismissAnimated:false];
                CFStringRef address = CTCallCopyAddress(kCFAllocatorDefault, (CTCallRef)[callsArray objectAtIndex:0]);
                DLogCFRetain(address);
                [$(SBTTYPromptAlert) dialNumberPromptingIfNecessary:(NSString*)address addressBookUID:0 urlAddition:nil];
                DLogCFRetain(address);
                CFRelease(address);
                [callsArray removeAllObjects];
            }
        } else if([displayedItems count] > 1) {
            int sheetHeight = ( 12.0 + ([displayedItems count])*(43.0 + 7.0) + 10.0 );
            int sheetY = round(self.frame.origin.y - (sheetHeight - self.frame.size.height)/2);
            
            CATransition *sheetAnimation= [CATransition animation];
            sheetAnimation.duration = .5f;
            sheetAnimation.type = @"rippleEffect";

            [self.layer addAnimation:sheetAnimation forKey:@"sheetAnimation"];
            [self setFrame:CGRectMake( self.frame.origin.x, sheetY, self.frame.size.width, sheetHeight)];
        }
    }
}
#endif

CHMethod(0, void, SBAwayItemsView, layoutSubviews) {
    NSArray *displayedItems = CHIvar(self, _displayedItems, NSArray *);
    if(PREF(@"ShowOnLockScreen") && [displayedItems count] > 1) {
        int enabledHeight = ( 12.0 + ([displayedItems count])*(43.0 + 7.0) + 10.0 );
        int height = (enabledHeight == self.frame.size.height) ? 43.0 : 30.0;
        int margin = (height == 43.0) ? 7.0 : 1.0;
        int cumulativeY = 12.0;
        for (UIButton *btn in self.subviews) {
            CGRect rect = [btn frame];
            rect.origin.y = cumulativeY;
            rect.size.height = height;
            [btn setFrame:rect];
            [btn setEnabled:( (height == 43.0) ? true : false )];
            cumulativeY = cumulativeY + height + margin;
        }
    } else
        CHSuper(0, SBAwayItemsView, layoutSubviews);
}

#ifndef IPHONE_OS_4
CHMethod(2, void, SBAwayItemsView, touchesCancelled, UIButton *, button, withEvent, UIEvent *, event) {
    if(!(PREF(@"ShowOnLockScreen") && [button isKindOfClass:$(UIButton)]))
        return;
    NSArray *displayedItems = CHIvar(self, _displayedItems, NSArray *);
    SBAwayItem *displayItem = [displayedItems objectAtIndex:[button tag]];
    // ------- remove all associated objects from SBAwayModel by address/type
    NSMutableArray *modelArray;
    NSMutableIndexSet *removeIndices = [NSMutableIndexSet indexSet];

    if([displayItem type] == 1) {
        modelArray = CHIvar([[$(SBAwayController) sharedAwayController] awayModel], _calls, NSMutableArray *);
        int index = 0;
        NSString *address;
        for(id call in modelArray) {
            if([displayItem uid] == 0) {
                //Because no address book uid, this takes the title string of the SBAwayItem and strips out all non-numeric characters,
                //Thus getting simply a phone number, then compares it the CTCallRef call address, if equal, set to remove from displayItems
                NSString *titleString = [displayItem title];
                CFStringRef callAddress = CTCallCopyAddress(kCFAllocatorDefault, (CTCallRef)call);
                NSMutableString *titleAddress = [NSMutableString stringWithCapacity:[titleString length]];
                NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"1234567890"];
                for(int i=0;i<[titleString length];i++) {
                    unichar currentChar = [titleString characterAtIndex:i];
                    if([charSet characterIsMember:currentChar])
                        [titleAddress appendFormat:@"%C",currentChar,nil];
                }
                if([titleAddress isEqualToString:(NSString*)callAddress]) {
                    [removeIndices addIndex:index];
                    address = (NSString*)callAddress;
                }
                CFRelease(callAddress);
            } else {
                //There is uid here, so we simply get ABRecords that match the title (which is a name), if the uid's match, set to remove
                int uid = [displayItem uid];
                ABAddressBookRef addressBook = ABAddressBookCreate();
                NSArray *titleRecords = (NSArray*)ABAddressBookCopyPeopleWithName(addressBook, (CFStringRef)[displayItem title]);
                for(id record in titleRecords) {
                    if(ABRecordGetRecordID((ABRecordRef)record) == uid) {
                        [removeIndices addIndex:index];
                        address = (NSString*)CTCallCopyAddress(kCFAllocatorDefault, (CTCallRef)call);
                    }
                }
                [(NSMutableArray*)titleRecords removeAllObjects];
                CFRelease(addressBook);
            }
            index++;
        }
        [modelArray removeObjectsAtIndexes:removeIndices];
        [$(SBTTYPromptAlert) dialNumberPromptingIfNecessary:address addressBookUID:-1 urlAddition:@"wasLockAlert=1"];
    } else if([displayItem type] == 0) {
        modelArray = CHIvar([[$(SBAwayController) sharedAwayController] awayModel], _SMSs, NSMutableArray *);
        //NSString *title = [displayItem title];
        int index = 0;
        for(CKMessage *message in modelArray) {
            NSString *msgName = [[[message conversation] recipient] name];
            NSString *title = [displayItem title];
            if ([title isEqualToString:msgName]) {
                [removeIndices addIndex:index];
                [QRView displayWithCKMessage:message];
            }
            index++;
        }
        [modelArray removeObjectsAtIndexes:removeIndices];
    }
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self reloadData];
    CGRect rect = self.frame;
    rect.origin.y = round(250.0 - (rect.size.height/2));
    [self setFrame:rect];
    [self setNeedsDisplay];
}
#endif

CHMethod(0, void, SBAwayItemsView, drawItems) {
    NSArray *displayedItems = CHIvar(self, _displayedItems, NSArray *);
    if(PREF(@"ShowOnLockScreen") && [displayedItems count] > 1) {
        if([[self subviews] count] == [displayedItems count])
            return;
        DLogFunc();
        [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        int cumulativeY = 12.0;
        NSInteger index = 0;
        for(SBAwayItem *displayItem in displayedItems) {
            id btn;
            if ([displayItem type] == 0 || [displayItem type] == 1) {
                btn = [UIButton buttonWithType:UIButtonTypeCustom];
                [btn setEnabled:false];
                
                UIImage *btnImg = [_UIImageWithName(@"UIPopupAlertSheetDefaultButton.png") stretchableImageWithLeftCapWidth:5 topCapHeight:0];
                [btn setBackgroundImage:btnImg forState:UIControlStateNormal];
                [btn setBackgroundImage:[[[UIImage alloc] init] autorelease] forState:UIControlStateDisabled];
                
                [btn addTarget:self action:@selector(touchesCancelled:withEvent:) forControlEvents:UIControlEventTouchUpInside];
            } else {
                btn = [[UIView alloc] init];
            }
            [btn setFrame:CGRectMake(11.0, cumulativeY, 262.0, 30.0)];
            [btn setAutoresizesSubviews:true];
            [btn setTag:index];
            
            UILabel *leftLabel = [[UILabel alloc] init];
            leftLabel.frame = CGRectMake(2.0,4.0, 130.0, 22.0); //Need to use _widestLabel of SBAwayItemsView to move labels to the left
            leftLabel.font = [UIFont boldSystemFontOfSize:18.0];
            leftLabel.textAlignment = UITextAlignmentRight;
            
            UILabel *rightLabel = [[UILabel alloc] init];
            rightLabel.frame = CGRectMake(151.0,4.0, 130.0, 22.0); //Need to use _widestLabel of SBAwayItemsView to move labels to the left
            rightLabel.font = [UIFont systemFontOfSize:18.0];
            rightLabel.textAlignment = UITextAlignmentLeft;
            
            leftLabel.textColor = rightLabel.textColor = [UIColor whiteColor];
            leftLabel.backgroundColor = rightLabel.backgroundColor = [UIColor clearColor];
            leftLabel.shadowColor = rightLabel.shadowColor = [UIColor blackColor];
            leftLabel.autoresizingMask = rightLabel.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | 
                                                                        UIViewAutoresizingFlexibleBottomMargin);
            
            [leftLabel setText:[displayItem title]];
            [rightLabel setText:[self _labelForAwayItem:displayItem count:0]];
            
            [btn addSubview:leftLabel];
            [btn addSubview:rightLabel];
            [leftLabel release];
            [rightLabel release];
            
            [self addSubview:btn];
            
            index++;
            cumulativeY = cumulativeY + 30.0 + 1.0; //30.0 for height of 1 button + 1 pixel for inbetween space
        }
        self.autoresizesSubviews = true;
    } else
        CHSuper(0, SBAwayItemsView, drawItems);
}

/*static int oToken, rToken;
static mach_port_t oPort;
static CFMachPortRef oPort2;
static CFRunLoopSourceRef oSource;

static void oChanged(CFMachPortRef port, void* msg, CFIndex size, void* info) {
    if(QR_IS_ACTIVE){
        int token = ((mach_msg_header_t*)msg)->msgh_id;
        uint64_t state;
        notify_get_state(token, &state);

        if(UIDeviceOrientationIsValidInterfaceOrientation( (UIDeviceOrientation)state )) {
            [[QRWindow sharedWindow] setOrientation:(UIInterfaceOrientation)state rawOrientation:( (token == oToken) ? false : true )];
        }
    }
}*/

#pragma mark Initialization
      
static __attribute__((constructor)) void QuickReplyInit() {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]) {
        
        if(!chooser()) {
            [pool release];
            return;
        }
        
        NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:PLIST_PATH];
        
        CHLoadLateClass(SBSMSAlertItem);
        CHLoadLateClass(SBAlertItemsController);
        CHLoadLateClass(SMSAlertSheet);
        CHLoadLateClass(SBAwayController);
        CHLoadLateClass(SBUIController);
        CHLoadLateClass(SpringBoard);
        CHLoadLateClass(SBAwayItemsView);
        CHLoadLateClass(CKSMSService);
        
        if (!settings){
            NSLog(@"QuickReply for SMS:Preference file not found");
            NSMutableDictionary *prefs = [[NSMutableDictionary alloc] init];
            [prefs setObject:[NSNumber numberWithBool:true] forKey:@"ShowOnLockScreen"];
            [prefs setObject:[NSNumber numberWithBool:true] forKey:@"AlertKeyboard"];
            [prefs setObject:[NSNumber numberWithBool:true] forKey:@"CallButton"];
            [prefs setObject:[NSNumber numberWithBool:true] forKey:@"ContactPicture"];
            [prefs setObject:[NSNumber numberWithBool:true] forKey:@"Landscape"];
            [prefs setObject:[NSNumber numberWithBool:true] forKey:@"LoadEarlierBtn"];
            [prefs writeToFile:PLIST_PATH atomically: TRUE];
            [prefs release];
            NSLog(@"QuickReply for SMS:New preference file created");
        }
        
        CHHook(2, SBSMSAlertItem, configure, requirePasscodeForActions);
        CHHook(2, SBSMSAlertItem, alertSheet, buttonClicked);
        
        CHHook(1, SBAlertItemsController, activateAlertItem);
        
        CHHook(0, SBUIController, clickedMenuButton);
        
        
        CHHook(1, CKSMSService, _sendError);
        
        CHHook(0, SMSAlertSheet, layoutSubviews);
        CHHook(1, SMSAlertSheet, sizeThatFits);
        
        CHHook(0, SBAwayController, smsMessageReceived);
        CHHook(0, SBAwayController, dimTimerFired);
        
        CHHook(2, SMSAlertSheet, touchesBegan, withEvent);
        CHHook(2, SMSAlertSheet, touchesMoved, withEvent);
        
        CHHook(0, SBAwayItemsView, layoutSubviews);
        CHHook(0, SBAwayItemsView, drawItems);
        
        DLogFunc();
        
        if ([[settings objectForKey:@"ShowOnLockScreen"] boolValue]){
            CHHook(2, SMSAlertSheet, touchesEnded, withEvent);
#ifndef IPHONE_OS_4
            CHHook(2, SBAwayItemsView, touchesEnded, withEvent);
            CHHook(2, SBAwayItemsView, touchesCancelled, withEvent); //Used to fake buttonClicked:event:
#endif
        }
        
        /*notify_register_mach_port("com.apple.springboard.orientation", &oPort, 0, &oToken);
        notify_register_mach_port("com.apple.springboard.rawOrientation", &oPort, NOTIFY_REUSE, &rToken);
        
        oPort2 = CFMachPortCreateWithPort(NULL, oPort, oChanged, NULL, NULL);
        oSource = CFMachPortCreateRunLoopSource(NULL, oPort2, 0);
        CFRunLoopAddSource(CFRunLoopGetMain(), oSource, kCFRunLoopDefaultMode);
        CFRelease(oSource);*/
            
#ifdef TESTING
        CHHook(0, SMSAlertSheet, layout);
        CHHook(1, SMSAlertSheet, layoutAnimated);
        CHHook(1, SMSAlertSheet, drawRect);
        
        CHHook(1, SBSMSAlertItem, willPresentAlertSheet);
        
        CHHook(0, SBAwayController, reactivatePendingAlertItems);
        CHHook(1, SBAwayController, _pendAlertItem);
        CHHook(0, SBAwayController, cleansePendingQueueOfAwayItems);
        CHHook(1, SBAwayController, allowsStackingOfAlert);
        CHHook(0, SBAwayController, pendOrDeactivateCurrentAlertItem);
        CHHook(1, SBAwayController, activateAlertItem);
        CHHook(0, SBAwayItemsView, reloadData);
        CHHook(1, SBAwayItemsView, drawRect);
#endif
        NSLog(@"QuickReply v%s successfully loaded", TWEAK_VERSION );
    }
    [pool release];
}