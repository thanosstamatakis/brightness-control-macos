//
//  blurhud.m
//  brightness-control
//
//  Created by Thanos Stamatakis on 5/11/21.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#include "BezelServices.h"
#include "OSD.h"
#include <dlfcn.h>

#ifdef OSD
bool useOsd;
#endif

void *(*_BSDoGraphicWithMeterAndTimeout)(CGDirectDisplayID arg0, BSGraphic arg1, int arg2, float v, int timeout) = NULL;
static const float brightnessStep = 100/16.f;

BOOL loadBezelServices(void)
{
    // Load BezelServices framework
    void *handle = dlopen("/System/Library/PrivateFrameworks/BezelServices.framework/Versions/A/BezelServices", RTLD_GLOBAL);
    if (!handle) {
        // MyLog(@"Error opening framework");
        return NO;
    }
    else {
        _BSDoGraphicWithMeterAndTimeout = dlsym(handle, "BSDoGraphicWithMeterAndTimeout");
        // MyLog(@"Will load");
        return _BSDoGraphicWithMeterAndTimeout != NULL;
    }
}

BOOL loadOSDFramework(void)
{
    return [[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/OSD.framework"] load];
}

void show_blur_hud(unsigned int screen_id, int brightness) {
    if (brightness > 100) brightness = 100;
    if (brightness < 0) brightness = 0;
    NSApplicationLoad();  // establish a connection to the window server. In <Cocoa/Cocoa.h>
    if (!loadBezelServices())
    {
        loadOSDFramework();
    }
    if (_BSDoGraphicWithMeterAndTimeout != NULL)
    {
        _BSDoGraphicWithMeterAndTimeout(screen_id, BSGraphicBacklightMeter, 0x0, brightness/100.f, 1);
    }
    else {
        [[NSClassFromString(@"OSDManager") sharedManager] showImage:OSDGraphicBacklight onDisplayID:screen_id priority:OSDPriorityDefault msecUntilFade:1000 filledChiclets:brightness/brightnessStep totalChiclets:100.f/brightnessStep locked:NO];
    }
}
