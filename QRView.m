/*
 *  QRView.mm -- QRView Class implementation
 *  
 *
 *  Created by Gaurav Khanna on 02/01/09.
 *  Copyright 2009 xShad0w. All rights reserved.
 *  Contact: Gauravk92@gmail.com
 *
 *  This file is part of iphone-quickreply or QuickReply.
 */

#import "QRView.h"

@implementation QRView

#define DALPHA 0.9

+ (void)displayWithCKMessage:(CKMessage *)message {
    if([[QRController sharedController] checkAddressInInstances:[message address]])
        [[[QRController sharedController] viewForAddressInInstances:[message address]] addMessage:message animated:true];
    else
        [[QRView alloc] _initWithCKMessage:message];
}

+ (void)_displayWithCKMessage:(CKMessage *)message orientation:(UIInterfaceOrientation)orientation{
    [[QRView alloc] _initWithCKMessage:message orientation:orientation];
}

+ (void)_displayWithCKMessage:(CKMessage *)message {
    [[QRView alloc] _initWithCKMessage:message];
}

- (void)_initWithCKMessage:(CKMessage *)message {
    [[QRView alloc] _initWithCKMessage:message orientation:UIInterfaceOrientationPortrait];
}
- (void)_initWithCKMessage:(CKMessage *)message orientation:(UIInterfaceOrientation)initOrientation {
    if ((self = [super initWithFrame:[UIScreen mainScreen].bounds])){
        self.frame = CGRectMake( 0.0, 0.0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-216.0);
        _message = [message retain];
        _fixedScrollView = true;
        _balloonY = 0.0;
        _messagesLoaded = 0;
        _earliestMessage = nil;
        [self refreshStatusBarHeight];
    }
    
    DLogFunc();
    
    self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.55];
    self.exclusiveTouch = true;
    self.autoresizesSubviews = true;
    
    //_controller = [[CKTranscriptController alloc] init];
    
    //_fakeNavBar = [[UIImageView alloc] initWithImage:_UIImageWithName(@"UINavigationBarBlackTranslucentBackground.png")];
    _fakeNavBar = [[UIImageView alloc] initWithImage:_UIImageWithName(@"UINavigationBarBlackOpaqueBackground.png")];
    _fakeNavBar.frame = CGRectMake(0.0, _statusBarHeight, 320.0, 44.0); // evaluate removing 1 pixel on statusbarheight in which modes
    _fakeNavBar.alpha = DALPHA;
    _fakeNavBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:_fakeNavBar];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)];
    titleLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
    titleLabel.text = [[message sender] name];
    titleLabel.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = UITextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
    titleLabel.shadowColor = [UIColor blackColor];
    titleLabel.shadowOffset = CGSizeMake(0.0,1.0);
    [_fakeNavBar addSubview:titleLabel];
    [titleLabel release];
    
    DLogFunc();
    
    float scrollHeight = (480.0-[CKMessageEntryView defaultHeight]-_statusBarHeight-216.0);
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake( 0.0, _statusBarHeight, 320.0, scrollHeight)];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _scrollView.backgroundColor = [UIColor clearColor];
    _scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite; // ??
    _scrollView.contentInset = _scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(44.0,0.0,0.0,0.0);
    _scrollView.autoresizesSubviews = TRUE;
    //_scrollView.contentOffset = CGPointMake(0.0,-5.0);
    
    DLogFunc();
    
    NSDictionary *mSMSsettings = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.MobileSMS.plist"];
    //------Used to see if MMS is enabled, if so add's media button on left side-------
    if([[mSMSsettings objectForKey:@"MMSEnabled"] boolValue]){
        _messageEntryView = [[CKMessageEntryView alloc] initWithFrame:CGRectMake(0.0 , _statusBarHeight+scrollHeight, 320.0 , 
                                                                                      [CKMessageEntryView defaultHeight])];
        [[(CKMessageMediaEntryView *)_messageEntryView photoButton] addTarget:_keyWindow 
                                                                       action:@selector(mediaButtonClicked:event:) 
                                                             forControlEvents:UIControlEventTouchUpInside];
    }else
        _messageEntryView = [[CKMessageEntryView alloc] initWithFrame:CGRectMake(0.0 , _statusBarHeight+scrollHeight, 320.0 , \
                                                                                 [CKMessageEntryView defaultHeight])];
    //---------------------------------------------------------------------------------
    
    DLogFunc();
    
    _messageEntryView.userInteractionEnabled = true;
    _messageEntryView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_messageEntryView setDelegate:self];
    CKContentEntryView *contentEntryView = [_messageEntryView entryField];
    [contentEntryView setEntryFieldDelegate:self];
    [contentEntryView setMessageComposition:[CKMessageComposition newComposition]];
    [self addSubview:_messageEntryView];
    [contentEntryView makeActive];
    
    DLogFunc();
    
    self.exclusiveTouch = TRUE;
    
    BOOL loadMore = FALSE;
    //NSArray *msgs = [[$(CKSMSService) sharedSMSService] messagesForConversation:[message conversation] limit:2 moreToLoad:&loadMore];
    AlwaysHighlightingPlacardButton *loadEarlierBtn = nil;
    if(PREF(@"LoadEarlierBtn") && loadMore) {
        loadEarlierBtn = [[AlwaysHighlightingPlacardButton alloc] initWithTitle:@"Load Earlier Messages"];
        loadEarlierBtn.frame = CGRectMake((_scrollView.center.x-150.0), _balloonY+5.0, 300.0, 33.0);
        loadEarlierBtn.alpha = 0.7f;
        loadEarlierBtn.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
        [loadEarlierBtn addTarget:self
                           action:@selector(loadEarlierButtonClicked:event:)
                 forControlEvents:UIControlEventTouchUpInside];
        _balloonY = _balloonY+loadEarlierBtn.frame.size.height+5.0;
    }
    
    DLogFunc();
    
    //------Used to take any alert items behind selected and dismiss/add here----------
    SBAlertItemsController *alertController = [$(SBAlertItemsController) sharedInstance];
    NSMutableArray *arr = CHIvar(alertController, _unlockedAlertItems, NSMutableArray *);
    id object;
    BOOL loadedEarliestMessage;
    while([arr count] > 0) {
        object = [arr objectAtIndex:0];
        if([object isKindOfClass:$(SBSMSAlertItem)] && [[object address] isEqualToString:[_message address]]){
            [self addMessage:CHIvar(object, _message, CKMessage *) animated:false];
            [alertController deactivateAlertItem:object];
            if(!loadedEarliestMessage){
                _earliestMessage = [CHIvar(object, _message, CKMessage *) retain];
                loadedEarliestMessage = TRUE;
            }
        }
    }
    //---------------------------------------------------------------------------------
    
    
    [self addMessage:_message animated:false];
    
    [self insertSubview:_scrollView belowSubview:_fakeNavBar];
    
    if(PREF(@"LoadEarlierBtn") && loadMore) {
        [_scrollView addSubview:loadEarlierBtn];
        [loadEarlierBtn release];
    }
    
    _keyWindow = [QRWindow sharedWindow];    
    _keyWindow.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
    _keyWindow.userInteractionEnabled = true;
    _keyWindow.hidden = false;
    [_keyWindow addSubview:self];
    
    if(PREF(@"AlertKeyboard")) {
        id activeView = CHIvar(contentEntryView, _activeView, UITextContentView *);
        [activeView setKeyboardAppearance:UIKeyboardAppearanceAlert];
        [(UITextContentView*)activeView resignFirstResponder];
        [(UITextContentView*)activeView becomeFirstResponder];
        
    } else {
        id activeView = CHIvar(contentEntryView, _activeView, UITextContentView *);
        [activeView setKeyboardAppearance:UIKeyboardAppearanceDefault];
        [(UITextContentView*)activeView resignFirstResponder];
        [(UITextContentView*)activeView becomeFirstResponder];
    }
    
    //[[UIAutoRotatingWindow sharedPopoverHostingWindow] makeKeyAndVisible];
    
    [self release];
    [[QRController sharedController] addAddressInInstances:[_message address] object:self];
    if([[[QRController sharedController] instances] count] == 1) {
        [[QRWindow sharedWindow] becomeKeyWindowAnimatedWithOrientation:initOrientation];
    } else {
        [self setAlpha:0];
        [_keyWindow makeKeyAndVisible];
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.7];
        [self setAlpha:1];
        [UIView commitAnimations];
    }
}

- (BOOL)isExclusiveTouch {
    return TRUE;
}

- (void)loadEarlierButtonClicked:(id)sender event:(id)event {
    CKConversation *conv = [( _earliestMessage ? _earliestMessage : _message ) conversation];
    BOOL loadMore;
    Class $CKSMSService = $(CKSMSService);
    NSArray *msgs;
    for(int i = 1;i < 6;i++) {
        DLogBOOL(loadMore);
        if(loadMore) {
            msgs = [[$CKSMSService sharedSMSService] messagesForConversation:conv limit:(i+2+_messagesLoaded) moreToLoad:&loadMore];
            DLogObject(msgs);
            [self addMessage:[msgs objectAtIndex:1] earlierMessage:true animated:false];
            DLogINT(i);
        }
    }
    _messagesLoaded+=5;
    if(!loadMore) {
        AlwaysHighlightingPlacardButton *loadEarlierButton = [self loadEarlierButton];
        _balloonY -= loadEarlierButton.frame.size.height+5.0;
        [loadEarlierButton removeFromSuperview];
    }
    [self refreshScrollViewAnimated:true setScroll:false];
    //_messagesLoaded+=5;
}

- (AlwaysHighlightingPlacardButton*)loadEarlierButton {
    for(id anObject in [_scrollView subviews]) {
        if([anObject isKindOfClass:$(AlwaysHighlightingPlacardButton)])
            return anObject;
    }
    return nil;
}

- (void)setOrientation:(UIInterfaceOrientation)newOrientation rawOrientation:(BOOL)raw{
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(newOrientation);
    if(isLandscape) {
        CGRect rect = self.frame;
        rect.size.width = 480.0;
        rect.size.height = (320.0-162.0);
        [self setFrame:rect];
        
        [self refreshStatusBarHeight];
        DLogBOOL(raw);
        _statusBarHeight = raw ? 0.0 : _statusBarHeight;
        
        [_scrollView setFrame:CGRectMake(0.0, _statusBarHeight, rect.size.width, rect.size.height-_messageEntryView.frame.size.height)];
        //if(!_fixedScrollView)
        //   [_scrollView setContentOffset:CGPointMake(0,(_scrollView.contentSize.height-_scrollView.frame.size.height)) animated:FALSE];
        /*CGSize size = _scrollView.contentSize;
        size.width=rect.size.width;
        [_scrollView setContentSize:size];*/
        
        CGRect rectM = _messageEntryView.frame;
        rectM.origin.y = rect.size.height-_messageEntryView.frame.size.height;
        [_messageEntryView setFrame:rectM];
        
        [_fakeNavBar setFrame:CGRectMake(0.0, _statusBarHeight, rect.size.width, 32.0)];
        
        //[self refreshScrollViewAnimated:FALSE setScroll:TRUE setScrollOffset:32.0];

    } else {
        CGRect rect = self.frame;
        rect.size.width = 320.0;
        rect.size.height = (480.0-216.0);
        [self setFrame:rect];
        
        [self refreshStatusBarHeight];
        //_statusBarHeight = raw ? 0.0 : _statusBarHeight;
        
        [_scrollView setFrame:CGRectMake(0.0, _statusBarHeight, rect.size.width, rect.size.height-_messageEntryView.frame.size.height)];
        CGSize size = _scrollView.contentSize;
        size.width=rect.size.width;
        [_scrollView setContentSize:size];
        //if(!_fixedScrollView)
        //  [_scrollView setContentOffset:CGPointMake(0,(_scrollView.contentSize.height-_scrollView.frame.size.height)) animated:FALSE];
        
        
        /*CGRect rectS = _scrollView.frame;
        rectS.origin.y = _statusBarHeight;
        rectS.size.height = rect.size.height-_messageEntryView.frame.size.height;
        rectS.size.width = rect.size.width;
        [_scrollView setFrame:rectS];*/
        
        CGRect rectM = _messageEntryView.frame;
        rectM.origin.y = rect.size.height-_messageEntryView.frame.size.height;
        [_messageEntryView setFrame:rectM];
        
        [_fakeNavBar setFrame:CGRectMake(0.0, _statusBarHeight, rect.size.width, 44.0)];
        
        //[self refreshScrollViewAnimated:FALSE setScroll:TRUE setScrollOffset:44.0];
    }
    [self refreshScrollViewAnimated:FALSE];
}

#pragma mark MEDIA BUTTON
- (void)mediaButtonClicked:(id)sender event:(id)event {
    [_keyWindow mediaButtonClickedSetDelegate:self];
}

#pragma mark ADD MESSAGE

- (void)addMessage:(id)message animated:(BOOL)animated{
    [self addMessage:message earlierMessage:FALSE animated:animated];
}

- (void)addMessage:(id)message earlierMessage:(BOOL)previous animated:(BOOL)animated {
    NSString *text = nil;
    BOOL MMS = false;
    if([message isKindOfClass:$(CKMessage)]) {
        MARK_MESSAGE_READ(message)
        if([[message messageParts] count] > 0) {
            id part;
            MMS = true;
            for (int i=0; i<[[message messageParts] count]; i++) {
                part = [[message messageParts] objectAtIndex:i];
                if([part isDisplayable]) {
                    if([part isKindOfClass:$(CKTextMessagePart)]) {
                        [self addMessage:[part text] animated:animated];
                    } else {
                        //DLogClass([[part mediaObject] balloonPreviewClassWithPreviewData:[part previewData]]);
                        
                        Class $CKBalloonClass = [[part mediaObject] balloonPreviewClassWithPreviewData:[part previewData]];
                        CKImageBalloonView *balloon = [[$CKBalloonClass alloc] init];
                        [balloon setDelegate:self];
                                                int tBalloonY = 0;
                        if(previous) {
                            _balloonY = tBalloonY-5.0;
                            if([message isOutgoing]) {
                                [balloon setOrientation:1];
                            } else
                                [balloon setOrientation:0];
                        } else
                            [balloon setOrientation:0];
                        [[part mediaObject] configureBalloon:balloon withPreviewData:[part previewData]];

                        if([balloon isKindOfClass:$(CKGenericFileBalloonView)]) {
                            
                        }else {
                            UIImage *composeImage = CHIvar(balloon, _img, UIImage *);
                            
                            UIButton *balloonButton = [UIButton buttonWithType:UIButtonTypeCustom];
                            balloonButton.adjustsImageWhenHighlighted = false;
                            balloonButton.transform = CGAffineTransformIdentity;
                            balloonButton.transform = CGAffineTransformMakeScale(-1.0, 1.0);
                            
                            if(previous) {
                                DLogFunc();
                                tBalloonY += _balloonY;
                                _balloonY = 38.0; // 5.0 + _loadEarlierButton.height + 5.0
                                DLogFunc();
                                for (id aSubview in [_scrollView subviews]) {
                                    if([aSubview isKindOfClass:$(CKBalloonView)] || \
                                       [aSubview isKindOfClass:$(UIButton)]) {
                                        CGRect tRect = [aSubview frame];
                                        tRect.origin.y += composeImage.size.height;
                                        [aSubview setFrame:tRect];
                                    }
                                }
                            }
                            
                            if(previous && [message isOutgoing]) {
                                CGRect rect = balloon.frame;
                                balloon.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
                                rect.origin.x = (_scrollView.frame.size.width-composeImage.size.width);
                                [balloon setFrame:rect];
                            }
                            
                            [balloonButton setFrame:CGRectMake(0.0, _balloonY+5.0, composeImage.size.width, composeImage.size.height)];
                            _balloonY = _balloonY+balloonButton.frame.size.height+5.0;
                            [balloonButton setBackgroundImage:composeImage forState:UIControlStateNormal];
                            [balloonButton setBackgroundImage:[part previewData] forState:UIControlStateDisabled];
                            balloonButton.userInteractionEnabled = TRUE;
                            [balloonButton addTarget:self action:@selector(bubbleTap:) forControlEvents:UIControlEventTouchUpInside];
                            [_scrollView addSubview:balloonButton];
                            [balloon release];
                        }
                    }
                }
            }
        }
    }
    if(!MMS) {
        if([message isKindOfClass:$(CKMessage)])
            text = [message text];
        else if([message isKindOfClass:$(NSString)])
            text = message;
        
        float balloonWidth = [text sizeWithFont:[CKBalloonView defaultFont]].width+34.0;
        float balloonHeight;
        if(balloonWidth > 238.0) {
            balloonHeight = [CKSimpleBalloonView heightForText:text width:238.0 includeBuffers:true];
            balloonWidth = 238.0;
        } else
            balloonHeight = [CKSimpleBalloonView minimumBubbleHeight];
        int tBalloonY = 0;
        if(previous) {
            DLogFunc();
            tBalloonY += _balloonY;
            _balloonY = 38.0; // 5.0 + _loadEarlierButton.height + 5.0
            DLogFunc();
            for(id aSubview in [_scrollView subviews]) {
                if([aSubview isKindOfClass:$(CKBalloonView)] || [aSubview isKindOfClass:$(UIButton)]) {
                    CGRect tRect = [aSubview frame];
                    tRect.origin.y += balloonHeight;
                    [aSubview setFrame:tRect];
                }
            }
        }
        CKSimpleBalloonView *balloon = [[$(CKSimpleBalloonView) alloc] initWithFrame:CGRectMake( 0.0, _balloonY+5.0, balloonWidth, balloonHeight) 
                                                                         delegate:self];
        if(previous) {
            _balloonY = tBalloonY;
            if([message isOutgoing]) {
                [balloon setOrientation:1];
                CGRect rect = balloon.frame;
                balloon.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
                rect.origin.x = (_scrollView.frame.size.width-balloonWidth);
                [balloon setFrame:rect];
            } else
                [balloon setOrientation:0];
        } else
            [balloon setOrientation:0];
        [balloon setText:text];
        [balloon setBackgroundColor:[UIColor clearColor]];
        
        _balloonY = _balloonY+balloonHeight;
        
        [_scrollView addSubview:balloon];
        DLogRetain(balloon);
        DLogRetain(_scrollView);
        [balloon release];
    }
    if(!previous)
        [self refreshScrollViewAnimated:animated];
}

- (void)refreshScrollViewAnimated:(BOOL)animated {
    [self refreshScrollViewAnimated:animated setScroll:TRUE];
}

- (void)refreshScrollViewAnimated:(BOOL)animated setScroll:(BOOL)setScroll{  
    //[self refreshScrollViewAnimated:animated setScroll:setScroll setScrollOffset:0.0];
    float desiredScrollOffset = 0.0f;
    int scrollHeight = (self.frame.size.height-_fakeNavBar.frame.size.height-_messageEntryView.frame.size.height-_statusBarHeight);
    if(scrollHeight < _balloonY) {
        DLogFunc();
        [_scrollView setContentSize:CGSizeMake(self.frame.size.width, _balloonY+5.0)];
        _fixedScrollView = false;
        
        [_scrollView setFrame:CGRectMake(_scrollView.frame.origin.x, (_messageEntryView.frame.origin.y-_scrollView.frame.size.height), \
                                         _scrollView.frame.size.width, _scrollView.frame.size.height)];
        /*CGRect rect = _scrollView.frame;
        rect.origin.y = (_messageEntryView.frame.origin.y-rect.size.height);
        [_scrollView setFrame:rect];*/
        _scrollView.contentInset = _scrollView.scrollIndicatorInsets = \
        UIEdgeInsetsMake((_statusBarHeight+_fakeNavBar.frame.size.height)-_scrollView.frame.origin.y, 0.0,0.0,0.0);
        if(setScroll){
            //float desiredScrollOffset = _scrollView.contentSize.height-_fakeNavBar.frame.size.height-(180.0-_statusBarHeight);
            //if(!_fixedScrollView) //|| scrollOffset == 0.0 )
                desiredScrollOffset = (_scrollView.contentSize.height-_scrollView.frame.size.height);
            //else
            //    desiredScrollOffset = (-1*_fakeNavBar.frame.size.height);
            DLogObject(_fakeNavBar);
        }
    }else if(setScroll)
        desiredScrollOffset = (-1*_fakeNavBar.frame.size.height);
    if(_scrollView.contentOffset.y != desiredScrollOffset)
        [_scrollView setContentOffset:CGPointMake(0.0, desiredScrollOffset) animated:animated];
}

- (void)refreshStatusBarHeight {
    if([UIApplication sharedApplication].statusBarHidden == true || [[$(SBStatusBarController) sharedStatusBarController] 
                                                                     statusBarMode] == 104)
        _statusBarHeight = 0.0;
    else 
        _statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    if(_statusBarHeight == 480.0)
        _statusBarHeight = 20.0;
    
}

- (void)bubbleTap:(UIButton *)button {
    // Implement preview for MMS images
}

- (BOOL)messageEntryView:(CKMessageEntryView *)messageEntryView contentSizeChanged:(struct CGSize)size animate:(BOOL)animate {
    //UIApplication *app = [UIApplication sharedApplication];
    DLog(@" %f %f %i %f", messageEntryView.frame.size.height, size.height, _statusBarHeight, _fakeNavBar.frame.size.height);
    float diff = size.height - messageEntryView.frame.size.height;
    float sizeHeight = (diff > 20.0) ? 180+_statusBarHeight : size.height;
    if(messageEntryView.frame.size.height!=size.height && (self.frame.size.height-sizeHeight)>= (_statusBarHeight+_fakeNavBar.frame.size.height)) {
        DLog(@"diff:%f",diff);
        DLog(@"scrollY:%f",_scrollView.frame.origin.y);
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:.1];
        [messageEntryView setFrame:CGRectMake(messageEntryView.frame.origin.x, \
                                              (self.frame.size.height-sizeHeight), \
                                              messageEntryView.frame.size.width, \
                                              sizeHeight)];
        if(!_fixedScrollView) {
            [_scrollView setFrame:CGRectMake(_scrollView.frame.origin.x, (_scrollView.frame.origin.y-diff), \
                                             _scrollView.frame.size.width, _scrollView.frame.size.height)];
        }
        [UIView commitAnimations];
        if(!_fixedScrollView) {
            float desiredEdgeInsetTop = (_scrollView.contentInset.top+diff);
            if(_scrollView.contentInset.top != desiredEdgeInsetTop)
                _scrollView.contentInset = _scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(desiredEdgeInsetTop,0.0,0.0,0.0);
            //float desiredScrollOffset = _scrollView.contentSize.height-_fakeNavBar.frame.size.height-(180.0-_statusBarHeight);
            float desiredScrollOffset = _scrollView.contentSize.height-_scrollView.frame.size.height;
            //DLog(@" contentOffset:%f desired:%f",_scrollView.contentOffset.y,desiredScrollOffset);
            if(_scrollView.contentOffset.y != desiredScrollOffset)
                [_scrollView setContentOffset:CGPointMake(0.0,desiredScrollOffset) animated:true];
        }
        //[self refreshScrollViewAnimated:TRUE];
    }
    return true;
}
- (void)messageEntryViewSendButtonHit:(CKMessageEntryView *)messageEntryView {
    _keyWindow.userInteractionEnabled = false;
    _messageEntryView.userInteractionEnabled = false;
    id sendButton = CHIvar(_messageEntryView, _sendButton, id);
    [sendButton setEnabled:false];
    if(messageEntryView != nil) {
        if([[messageEntryView entryField] hasContent]){
#ifndef IPHONE_OS_4
            if(_statusBarHeight != 0.0)
                [_keyWindow startSendingAnimated:true];
#endif
            CKService *service = [CKSMSService sharedSMSService];
            DLogObject(service);
            CKSMSMessage *msg = [service newMessageWithComposition:[[messageEntryView entryField] messageComposition] 
                                                   forConversation:[[(QRView*)[messageEntryView delegate] message] conversation]];
            DLogObject(msg);
            [msg markAsRead];
            DLogFunc();
            [service sendMessage:msg];
            DLogFunc();
        }
    }
    [self resignAnimated:[NSNumber numberWithBool:true]];
}

- (void)resignAnimated:(NSNumber *)animated {
    if([animated boolValue]){
        [[QRController sharedController] removeAddressInInstances:[_message address] object:self]; //Want it removed if animating out
        if([[[QRController sharedController] instances] count] == 0) {
            [[QRWindow sharedWindow] resignKeyWindowAnimated];
        }else {
            QRView *temp = [[QRWindow sharedWindow] getFrontMostView];
            [temp refresh];
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector: @selector(removeFromSuperview)];
            [UIView setAnimationDuration:0.7];
            [self setAlpha:0];
            [UIView commitAnimations];
        }
    }else{
        [self removeFromSuperview];
    }
}

- (CKMessageEntryView *)messageEntryView {
    return _messageEntryView;
}
- (CKMessage *)message {
    return _message;
}

- (void)refresh {
    self.window.userInteractionEnabled = true;
    self.exclusiveTouch = true;
}

- (void)dealloc {
    [_fakeNavBar release];
    [_messageEntryView release];
    [_scrollView release];
    [_message release];
    if(_earliestMessage != nil)
        [_earliestMessage release];
    [super dealloc];
}

- (void)entryFieldDidBecomeActive:(CKContentEntryView *)contentEntryView {
    [[[QRWindow sharedWindow] keyboard] defaultTextInputTraits];
}
- (BOOL)entryFieldShouldBecomeActive:(CKContentEntryView *)contentEntryView {return true; }
- (void)entryFieldAttachmentsChanged:(CKContentEntryView *)contentEntryView {}
- (void)entryFieldContentChanged:(CKContentEntryView *)contentEntryView{
    UIButton *sendButton = CHIvar([[contentEntryView entryFieldDelegate] messageEntryView], _sendButton, UIButton *);
    if(![contentEntryView hasContent]) {
        NSString *doneTitle = NSLocalStringCK(@"DONE");
        [sendButton setTitle:doneTitle forState:UIControlStateNormal];
    } else {
        NSString *sendTitle = NSLocalStringCK(@"SEND_TITLE");
        if(!([[sendButton titleForState:UIControlStateNormal] isEqualToString:sendTitle]))
            [sendButton setTitle:sendTitle forState:UIControlStateNormal];
    }
}
- (void)entryFieldSubjectChanged:(CKContentEntryView *)contentEntryView {}
- (BOOL)entryField:(CKContentEntryView *)contentEntryView shouldInsertMediaObject:(id)mediaObject {
    if(PREF(@"MMSEnabled"))
        return true;
    else
        return false;
}

- (BOOL)entryField:(id)entryField shouldChangeContentTextInRange:(NSRange)range replacementText:(id)text {
    return TRUE;
}

- (void)clippedTargetRectForBalloon:(id)balloon {}

- (void)restoreBalloonStateAfterRotation:(id)balloon {}
    
    
    
@end



