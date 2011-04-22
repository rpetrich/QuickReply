//
//  QRChooser.m
//  
//
//  Created by Gaurav Khanna on 6/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CaptainHook/CaptainHook.h>
#include <dlfcn.h>
#include "../DRM.h"

CHConstructor {    
    
    if(!chooser()) {
        return;
    }
    
    int os_version = 0;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]) {
        if(![[NSFileManager defaultManager] fileExistsAtPath:@"/System/Library/Frameworks/iAd.framework"])
            os_version = 3;
        else
            os_version = 4;
    }
    [pool release];
    if(os_version == 3) {
        NSLog(@"QuickReply for SMS: 3.x Detected - Loading QuickReply 1.5.3");
        void *handle;
#define ROCK
#ifdef ROCK
        handle = dlopen("/Library/QuickReply/quickreply3r.dylib", RTLD_LAZY);
#else
        handle = dlopen("/Library/QuickReply/quickreply3.dylib", RTLD_LAZY);
#endif
    } else if(os_version == 4) {
        NSLog(@"QuickReply for SMS: iOS4 Detected - Loading latest QuickReply");
        void *handle;
        handle = dlopen("/Library/QuickReply/quickreply4.dylib", RTLD_LAZY);
        if(handle) {
            void (*init)() = dlsym(handle, "QuickReplyInit");
            if(init)
                init();
        }
    }
}
