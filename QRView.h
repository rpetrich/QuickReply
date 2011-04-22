/*
 *  QRView.h
 *  
 *
 *  Created by Gaurav Khanna on 11/28/09.
 *  Copyright 2009 xShad0w. All rights reserved.
 *
 */

#import <UIKit/UIKit.h>
#import <ChatKit/ChatKit.h>
#import <SpringBoard/SpringBoard.h>

#import "QRController.h"
#import "QRWindow.h"

@class QRWindow, QRController;

@interface QRView : UIView <CKContentEntryFieldDelegate> {
    CKMessage *_message;
    CKMessage *_earliestMessage;
    QRWindow *_keyWindow;
    CKMessageMediaEntryView *_messageEntryView;
    UIImageView *_fakeNavBar;
    UIScrollView *_scrollView;
    //CKTranscriptController *_controller;
    BOOL _fixedScrollView;
    int _balloonY;
    int _statusBarHeight;
    int _messagesLoaded;
}

+ (void)displayWithCKMessage:(CKMessage *)message;
+ (void)_displayWithCKMessage:(CKMessage *)message orientation:(UIInterfaceOrientation)orientation;
+ (void)_displayWithCKMessage:(CKMessage *)message;
- (void)_initWithCKMessage:(CKMessage *)message;
- (void)_initWithCKMessage:(CKMessage *)message orientation:(UIInterfaceOrientation)initOrientation;
- (void)loadEarlierButtonClicked:(id)sender event:(id)event;
- (AlwaysHighlightingPlacardButton*)loadEarlierButton;
- (void)setOrientation:(UIInterfaceOrientation)newOrientation rawOrientation:(BOOL)raw;
- (void)mediaButtonClicked:(id)sender event:(id)event;
- (void)addMessage:(id)message animated:(BOOL)animated;
- (void)addMessage:(id)message earlierMessage:(BOOL)previous animated:(BOOL)animated;
- (void)refreshScrollViewAnimated:(BOOL)animated;
- (void)refreshScrollViewAnimated:(BOOL)animated setScroll:(BOOL)setScroll;
- (void)refreshStatusBarHeight;
- (void)bubbleTap:(UIButton *)button;
- (BOOL)messageEntryView:(CKMessageEntryView *)messageEntryView contentSizeChanged:(struct CGSize)size animate:(BOOL)animate;
- (void)messageEntryViewSendButtonHit:(CKMessageEntryView *)messageEntryView;
- (void)resignAnimated:(NSNumber *)animated;
- (CKMessageEntryView *)messageEntryView;
- (CKMessage *)message;
- (BOOL)isExclusiveTouch;
- (void)refresh;

@end