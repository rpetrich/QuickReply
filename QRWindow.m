/*
 *  QRWindow.mm -- QRWindow Class implementation
 *  
 *
 *  Created by Gaurav Khanna on 02/01/09.
 *  Copyright 2009 xShad0w. All rights reserved.
 *  Contact: Gauravk92@gmail.com
 *
 *  This file is part of iphone-quickreply or QuickReply.
 */

#import "QRWindow.h"

@implementation QRWindow

@synthesize orientation = _orientation;

MAKE_SINGLETON(QRWindow, sharedWindow);

#pragma mark STATUS_BAR_ANIMATION
// work on switching to class methods
- (void)startSendingAnimated:(BOOL)animated {
    [[$(SpringBoard) sharedApplication] addStatusBarImageNamed:@"QRSMS"];
    if(animated)
        [self performSelector:@selector(startSBAnimation) withObject:nil afterDelay:.05];
    [self performSelector:@selector(endSending) withObject:nil afterDelay:9.0];
}

- (void)startSBAnimation {
    SBStatusBarContentsView *view = CHIvar([$(SBStatusBarController) sharedStatusBarController], _statusBarContentsView, SBStatusBarContentsView *);
    NSMutableArray *arr = CHIvar(view, _indicatorViews, NSMutableArray *);
    
    for (id anObject in arr) {
        if([[anObject indicatorName] isEqualToString:@"QRSMS"]) {
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:1.5];
            [anObject setAlpha:1.0];
            [UIView setAnimationRepeatCount:2.5];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDidStopSelector:@selector(endSending)];
            [UIView setAnimationRepeatAutoreverses:true];
            [anObject setAlpha:0.0];
            [UIView commitAnimations];
        }
    }
}

- (void)endSending {
    [[$(SpringBoard) sharedApplication] removeStatusBarImageNamed:@"QRSMS"];
}

+ (void)setAccelerometerState:(BOOL)state {
    DLogFunc();
    Class $SBAccelerometerInterface = $(SBAccelerometerInterface);
	SBAccelerometerInterface* interface = [$SBAccelerometerInterface sharedInstance];
	SBAccelerometerClient* client = [CHIvar(interface, _clients, NSMutableArray *) lastObject];
	client.updateInterval = state ? 0.1 : 0;
	[interface updateSettings];
}

- (id)init {
    return [self initWithFrame:[UIScreen mainScreen].bounds];
}

- (QRWindow *)initWithFrame:(CGRect)rect {
    CGRect x_fullScreenRect = [UIScreen mainScreen].bounds;
    if((self = [super initWithFrame:rect])){
        
        _kbWindow = nil;
        
        [UITextEffectsWindow sharedTextEffectsWindow].windowLevel = 3*UIWindowLevelStatusBar;
        [UITextEffectsWindow sharedTextEffectsWindowAboveStatusBar].windowLevel = 3*UIWindowLevelStatusBar;
        
        _fullScreenRect = x_fullScreenRect;
        self.autoresizesSubviews = true;
        _kbRectPortrait = [UIKeyboard defaultFrameForInterfaceOrientation:UIInterfaceOrientationPortrait];
		_kbRectLandscape = [UIKeyboard defaultFrameForInterfaceOrientation:UIDeviceOrientationLandscapeRight];
		CGFloat t = _kbRectLandscape.origin.x; _kbRectLandscape.origin.x = _kbRectLandscape.origin.y; _kbRectLandscape.origin.y = t;
		t = _kbRectLandscape.size.width; _kbRectLandscape.size.width = _kbRectLandscape.size.height; _kbRectLandscape.size.height = t;
		[UIKeyboard initImplementationNow];
        
        _keyboard = [[UIKeyboard alloc] initWithDefaultSize];

        [_keyboard setDefaultTextInputTraits:[UITextInputTraits defaultTextInputTraits]];
		_keyboard.frame = _kbRectPortrait;
        
        [self addSubview:_keyboard];
        _kbWindow.hidden = FALSE;
        _keyboard.hidden = FALSE;
        
		[_keyboard release];
        self.exclusiveTouch = TRUE;
    }
    return self;
}



//Used so that the keyboard UIView will stay ontop always
- (void)addSubview:(UIView *)view {
    [super addSubview:view];
    if(![view isKindOfClass:$(UIKeyboard)]){
        if([view isKindOfClass:$(UIActionSheet)]){
            [self insertSubview:view aboveSubview:_keyboard];
            [self bringSubviewToFront:view];
        }else {
            [self insertSubview:view belowSubview:_keyboard];
            [QRWindow setAccelerometerState:true];
        }
    }
}

- (void)becomeKeyWindow {
    [self makeKeyAndVisible];
}

+ (UIInterfaceOrientation)convertAngleToInterfaceOrientation:(int)angle {
    switch (angle) {
		default: return UIInterfaceOrientationPortrait;
		case -90: return UIInterfaceOrientationLandscapeLeft;
		case 90: return UIInterfaceOrientationLandscapeRight;
		case 180: return UIInterfaceOrientationPortraitUpsideDown;
	}
}

+ (UIInterfaceOrientation)convertModeToInterfaceOrientation:(int)mode {
    switch (mode) {
        case 3: return UIInterfaceOrientationLandscapeRight;
        case 4: return UIInterfaceOrientationLandscapeLeft;
        case 1: return UIInterfaceOrientationPortrait;
        default: return UIInterfaceOrientationPortrait;
    }
}

// Used to animate window and initial view in
- (void)becomeKeyWindowAnimatedWithOrientation:(UIInterfaceOrientation)initOrientation {
    [self setAlpha:0];
    [_kbWindow setAlpha:0];
    _kbWindow = [UIAutoRotatingWindow sharedPopoverHostingWindow];
    [[UIAutoRotatingWindow sharedPopoverHostingWindow] setHidden:FALSE];
    [[UIAutoRotatingWindow sharedPopoverHostingWindow] makeKeyAndVisible];
    [self makeKeyAndVisible];
    
    [self windowRotateToInterfaceOrientation:initOrientation duration:0.0 raw:FALSE];
    _orientation = initOrientation;
    
    [UITextEffectsWindow sharedTextEffectsWindow].windowLevel = 3*UIWindowLevelStatusBar;
    [UITextEffectsWindow sharedTextEffectsWindowAboveStatusBar].windowLevel = 3*UIWindowLevelStatusBar;
    
    if([[$(SBAwayController) sharedAwayController] isLocked]) {
        self.windowLevel = 1000.0f;
        //[[UIKeyboard containerWindow] setWindowLevel:100.0f];
    } else {
        //window level for mail app keyboard is 1.0f, needs to go on top
        self.windowLevel = 2.0f;
        //[[UIKeyboard containerWindow] setWindowLevel:2.0f];
    }
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.7];
    [self setAlpha:1];
    [_kbWindow setAlpha:1];
    [UIView commitAnimations];
}

- (UIKeyboard *)keyboard {
    return _keyboard;
}

- (void)makeKeyAndVisible {
    [super makeKeyAndVisible];
    [self setWindowLevel:1000.0f];
}

- (void)resignKeyWindowAnimated {
    self.userInteractionEnabled = false;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector: @selector(resignAsKeyWindow)];
    [UIView setAnimationDuration:0.7];
    // [[UIKeyboard automaticKeyboard] orderOutWithAnimation:true];
    [self setAlpha:0];
    [_kbWindow setAlpha:0];
    [UIView commitAnimations];
}

// don't want other windows/view removing quickreply, instead keeps it on top
- (void)resignKeyWindow {
    [self makeKeyAndVisible];
}
- (void)resignAsKeyWindow {
    if([[$(SBAwayController) sharedAwayController] isLocked])
        [[$(SBAwayController) sharedAwayController] restartDimTimer:8.0f];
    self.hidden = true;
    self.alpha = 1;
    _kbWindow.hidden = TRUE;
    _kbWindow.alpha = 1;
    [$(UIApplication) sharedApplication].statusBarOrientation = UIInterfaceOrientationPortrait;
    [QRWindow setAccelerometerState:false];
    if(_picker)
        [_picker.view removeFromSuperview];
    [[self subviews] makeObjectsPerformSelector:@selector(resignAnimated:) withObject:[NSNumber numberWithBool:false]];
}
- (id)getFrontMostView {
    NSArray *arr = [self subviews];
    return [[arr subarrayWithRange:NSMakeRange(0,([arr count]-1))] lastObject];
}
- (void)removeFromSuperView {
    
}

#pragma mark ORIENTATION

- (BOOL)isExclusiveTouch {
    return TRUE;
}

- (BOOL)shouldWindowUseOnePartInterfaceRotationAnimation:(UIWindow*)window { 
    DLogFunc();
    return NO; 
}
- (UIView*)rotatingContentViewForWindow:(UIWindow*)window { 
    DLogFunc();
    return self; 
}
- (void)setAutorotates:(BOOL)autorotates forceUpdateInterfaceOrientation:(BOOL)orientation {
    DLogFunc();
}
- (void)windowRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration raw:(BOOL)raw {
	//BOOL wasLandscape = UIInterfaceOrientationIsLandscape(_orientation), 
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(interfaceOrientation);
    if(PREF(@"Landscape")) {
        DLogFunc();
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:duration];
        [self updateForOrientation:interfaceOrientation];
        [$(UIApplication) sharedApplication].statusBarOrientation = interfaceOrientation;
        
        CGSize selfBounds;
        if (isLandscape) {
            selfBounds = CGSizeMake(_fullScreenRect.size.height, _fullScreenRect.size.width);
        } else {
            selfBounds = _fullScreenRect.size;
        }
        self.bounds = CGRectMake(0, 0, selfBounds.width, selfBounds.height);
        
        CGFloat kbHeight, kbWidth, sbHeight;
        if (isLandscape) {
            kbHeight = _kbRectLandscape.size.height;
            kbWidth = _kbRectLandscape.size.width;
            sbHeight = _fullScreenRect.size.width;
            _keyboard.frame = _kbRectLandscape;
        } else {
            kbHeight = _kbRectPortrait.size.height;
            kbWidth = _kbRectPortrait.size.width;
            sbHeight = _fullScreenRect.size.height;
            _keyboard.frame = _kbRectPortrait;
        }
        
        if(isLandscape) {
            self.windowLevel = 2000.0f;
            //[[UIKeyboard containerWindow] setWindowLevel:2000.0f];
        } else {
            if([[$(SBAwayController) sharedAwayController] isLocked]) {
                self.windowLevel = 100.0f;
                //[[UIKeyboard containerWindow] setWindowLevel:100.0f];
            } else {
                //window level for mail app keyboard is 1.0f, needs to go on top
                self.windowLevel = 2.0f;
                //[[UIKeyboard containerWindow] setWindowLevel:2.0f];
            }
        }
        
        for (id anObject in self.subviews)
            if([anObject isKindOfClass:$(QRView)])
                [anObject setOrientation:interfaceOrientation rawOrientation:raw];
        
    //		if (_attachedToKeyboardView) {
    //			CGFloat h = _attachedToKeyboardView.frame.size.height;
    //			_attachedToKeyboardView.frame = CGRectMake(0, sbHeight-kbHeight-h, kbWidth, h);
    //		}
        [UIView commitAnimations];
        self.exclusiveTouch = true;
	}
}

- (void)setOrientation:(UIInterfaceOrientation)newOrientation rawOrientation:(BOOL)rawOrientation {
	if (_orientation != newOrientation  && newOrientation != UIInterfaceOrientationPortraitUpsideDown) {
        [[UITextEffectsWindow sharedTextEffectsWindowAboveStatusBar] setWindowLevel:(3*UIWindowLevelStatusBar)];
        [self windowRotateToInterfaceOrientation:newOrientation duration:.4f raw:rawOrientation];
        _orientation = newOrientation;
	}
}

- (BOOL)acceptsGlobalPoint:(CGPoint)point {
    return TRUE;
}

#pragma mark IMAGE_PICKER

- (void)showPickerOfType:(UIImagePickerControllerSourceType)sourceType delegate:(id)delegate {
    DLogBOOL([UIImagePickerController isSourceTypeAvailable:sourceType]);
    DLogObject(self);
    DLogObject(delegate);
     if([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        //_pickerDelegate = delegate;
        _picker = [[UIImagePickerController alloc] init];
        _picker.delegate = self;
        _picker.sourceType = sourceType;
         //[_picker setAllowsEditing:true];
         _picker.mediaTypes = [NSArray arrayWithObjects:@"public.image", nil];
        //_picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
        //[_picker.view setAlpha:0];
        //_picker.view.hidden = true;
         //[self addSubview:_picker.view];
        [self insertSubview:_picker.view aboveSubview:_keyboard];
         
         
         
         CATransition *animation = [CATransition animation];
         //[animation setDelegate:self];
         _pickerLayer = [_picker.view layer];
         [animation setDuration:.3];
         [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
         [animation setType:kCATransitionMoveIn];
         [animation setSubtype:kCATransitionFromTop];
         [_pickerLayer addAnimation:animation forKey:@"slidePickerIn"];
         
         
         //[UIView beginAnimations:nil context:NULL];
         //[UIView setAnimationDuration:0.5];
         //[_picker.view setAlpha:1];
         //[UIView commitAnimations];
         DLogRetain(_picker);
         //[_picker release];
    }else {
        
    }
}

- (void)mediaButtonClickedSetDelegate:(id)delegate {
    //[_scrollView setNeedsLayout];
    _pickerDelegate = delegate;
    //NSBundle *bundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/ChatKit.framework"];
    UIActionSheet *sheet = [[UIActionSheet alloc] init];
    [sheet setDelegate:self];
    //    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    //        [sheet addButtonWithTitle:NSLocalStringCK(@"TAKE_PHOTO")];
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
        [sheet addButtonWithTitle:NSLocalStringCK(@"CHOOSE_EXISTING")];
    [sheet setCancelButtonIndex:[sheet addButtonWithTitle:NSLocalStringCK(@"CANCEL")]];
    [sheet showInView:self];
    [sheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if([actionSheet numberOfButtons]-1 != buttonIndex){
        //NSBundle *bundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/ChatKit.framework"];
        if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalStringCK(@"TAKE_PHOTO")])
            [self showPickerOfType:UIImagePickerControllerSourceTypeCamera delegate:_pickerDelegate];
        else
            [self showPickerOfType:UIImagePickerControllerSourceTypePhotoLibrary delegate:_pickerDelegate];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    //[_picker retain];
    /*[_picker.view setAlpha:1];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:_picker.view];
    //[UIView setAnimationDidStopSelector: @selector(removeFromSuperview)];
    [_picker.view setAlpha:0];
    [UIView commitAnimations];*/
    [self imagePickerControllerDidCancel:picker];
    DLogRetain(_picker.view);
    DLogRetain(_picker);
    UIImage *origImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    //DLogObject(origImage);
    NSData *theData = UIImageJPEGRepresentation(origImage, 0.5f);
    //[origImage release];
    //DLogFunc();
    Class $CKMediaObjectManager = $(CKMediaObjectManager);
    id mediaObject = [[$CKMediaObjectManager sharedInstance] newMediaObjectForData:theData 
                                                                          mimeType:@"image/jpeg" 
                                                                  exportedFilename:nil];
    Class $CKMediaObjectMessagePart = $(CKMediaObjectMessagePart);
    id mediaObjectPart = [[$CKMediaObjectMessagePart alloc] initWithMediaObject:mediaObject];
    [mediaObject release];
    [[[(QRView*)_pickerDelegate messageEntryView] entryField] insertMessagePart:mediaObjectPart];
    [mediaObjectPart release];
    //DLogRetain(theImage);
    //DLogRetain(mediaObject);
    //DLogRetain(mediaObjectPart);
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    //[_picker.view setAlpha:1];
    //[UIView beginAnimations:nil context:NULL];
    //[UIView setAnimationDuration:0.5];
    //[UIView setAnimationDelegate:_picker.view];
    //[UIView setAnimationDidStopSelector: @selector(removeFromSuperview)];
    //[_picker.view setAlpha:0];
    //[UIView commitAnimations];
    
    [_picker.view removeFromSuperview];
    [self bringSubviewToFront:_pickerDelegate];
    
    CATransition *animation = [CATransition animation];
    //[animation setDelegate:self];
    [animation setDuration:.3];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [animation setType:kCATransitionReveal];
    [animation setSubtype:kCATransitionFromBottom];
    [[self layer] addAnimation:animation forKey:@"slidePickerIn"];
    //[self release];
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {  
    //[_picker.view removeFromSuperview];
    //_picker = nil;
}

@end
