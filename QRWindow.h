/*
 *  QRWindow.h
 *  
 *
 *  Created by Gaurav Khanna on 11/28/09.
 *  Copyright 2009 xShad0w. All rights reserved.
 *
 */

#import <UIKit/UIKit.h>
#import <ChatKit/ChatKit.h>
#import <singleton.h>

#import "QRView.h"

@class QRView;

@interface QRWindow : UIWindow <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate> {
    UIKeyboard *_keyboard;
    UIAutoRotatingWindow *_kbWindow; // Weak Ivar;
    UIImagePickerController *_picker;
    CGRect _kbRectPortrait;
    CGRect _kbRectLandscape;
    id _pickerDelegate;
    UIInterfaceOrientation _orientation;
    CGRect _fullScreenRect;
    id _pickerLayer;
}

@property(assign,nonatomic) UIInterfaceOrientation orientation;

+ (QRWindow *)sharedWindow;
- (void)windowRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration raw:(BOOL)raw;
+ (UIInterfaceOrientation)convertModeToInterfaceOrientation:(int)mode;
- (void)resignKeyWindowAnimated;
- (void)setOrientation:(UIInterfaceOrientation)newOrientation rawOrientation:(BOOL)rawOrientation;
- (void)becomeKeyWindowAnimatedWithOrientation:(UIInterfaceOrientation)initOrientation;
- (void)mediaButtonClickedSetDelegate:(id)delegate;
- (void)startSendingAnimated:(BOOL)animated;
- (id)getFrontMostView;
- (UIKeyboard *)keyboard;

/*
- (void)startSendingAnimated:(BOOL)animated 
- (void)startSBAnimation 
- (void)endSending 
+ (void)setAccelerometerState:(BOOL)state 
- (QRWindow *)initWithFrame:(CGRect)rect 
+ (UIInterfaceOrientation)convertAngleToInterfaceOrientation:(int)angle 
+ (UIInterfaceOrientation)convertModeToInterfaceOrientation:(int)mode 
- (void)becomeKeyWindowAnimatedWithOrientation:(UIInterfaceOrientation)initOrientation 
- (void)resignKeyWindowAnimated
- (void)resignKeyWindow 
- (void)resignAsKeyWindow 
- (id)getFrontMostView 
- (void)setOrientation:(UIInterfaceOrientation)newOrientation rawOrientation:(BOOL)rawOrientation 
- (void)showPickerOfType:(UIImagePickerControllerSourceType)sourceType delegate:(id)delegate {
- (void)mediaButtonClickedSetDelegate:(id)delegate 
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info 
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker 
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag */
@end