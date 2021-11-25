//
//  CaptureKeyboardEvents.swift
//  brightness-control
//
//  Created by Thanos Stamatakis on 6/11/21.
//

import Foundation
import Combine
import Cocoa
import SwiftUI

class Tap {
    @ObservedObject var screenModel: DDCCIScreenModel;
    var eventTap: CFMachPort!
    var selfPtr: Unmanaged<Tap>!
    init(screenModel: DDCCIScreenModel) {
        self.screenModel = screenModel;
        let eventMask: CGEventMask = UInt64(NX_KEYDOWNMASK) | UInt64(NX_KEYUPMASK) | UInt64(NX_FLAGSCHANGEDMASK);
        
        selfPtr = Unmanaged.passRetained(self)

        eventTap = CGEvent.tapCreate(
            tap: CGEventTapLocation.cgSessionEventTap,
            place: CGEventTapPlacement.headInsertEventTap,
            options: CGEventTapOptions.defaultTap,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, refcon in
                let mySelf = Unmanaged<Tap>.fromOpaque(refcon!).takeUnretainedValue()
                return mySelf.eventTapCallback(proxy: proxy, type: type, event: event, refcon: refcon)
            },
            userInfo: selfPtr.toOpaque())!

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        CFRunLoopRun()
    }

    func eventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
        if type == CGEventType.tapDisabledByUserInput {
            return nil;
        }

        if #available(OSX 10.12.2, *) {
            if let cocoaEvent = NSEvent(cgEvent: event) {
                if cocoaEvent.type == NSEvent.EventType.directTouch {
                    print("Touch bar touch")
                }
            }
        }

        switch type {
            case .keyDown:
                let num = event.getIntegerValueField(.keyboardEventKeycode);
                if (num == 122 || num == 120) {
                    let screens = self.screenModel.ddcciscreens;
                    // If user presses F1
                    if (num == 122) {
                        for screen in screens {
                            var brightnessVal = screen.brightness;
                            brightnessVal -= 6;
                            if (brightnessVal < 0) {
                                brightnessVal = 0;
                            }else if (brightnessVal > 100){
                                brightnessVal = 100;
                            }
                            if (screen.brightness == brightnessVal) {
                                show_blur_hud(UInt32(screen.id), Int32(brightnessVal));
                            }else {
                                self.screenModel.updateBrightness(for: screen.id, to: brightnessVal);
                                DDCCI.setBrightness(screenId: UInt32(screen.id), brightness: UInt8(brightnessVal));
                                show_blur_hud(UInt32(screen.id), Int32(brightnessVal));
                            }
                        }
                    // If user presses F2
                    }else if (num == 120) {
                        for screen in screens {
                            var brightnessVal = screen.brightness;
                            brightnessVal += 6;
                            if (brightnessVal < 0) {
                                brightnessVal = 0;
                            }else if (brightnessVal > 100){
                                brightnessVal = 100;
                            }
                            if (screen.brightness == brightnessVal) {
                                show_blur_hud(UInt32(screen.id), Int32(brightnessVal));
                            }else {
                                self.screenModel.updateBrightness(for: screen.id, to: brightnessVal);
                                DDCCI.setBrightness(screenId: UInt32(screen.id), brightness: UInt8(brightnessVal));
                                show_blur_hud(UInt32(screen.id), Int32(brightnessVal));
                            }
                        }
                    }
                    
                    return nil;
                }
                break
        default:
            break
        }

        return Unmanaged.passUnretained(event)
    }

    func done() {
        CGEvent.tapEnable(tap: self.eventTap, enable: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let _ = self.selfPtr.autorelease()
        }
    }
}

public func checkAccess() -> Bool{
    let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
    let options = [checkOptPrompt: true]
    let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary?)
    return accessEnabled
}
