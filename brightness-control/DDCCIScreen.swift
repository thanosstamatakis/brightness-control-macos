//
//  DDCCIScreen.swift
//  brightness-control
//
//  Created by Thanos Stamatakis on 4/11/21.
//
import SwiftUI
import Combine

struct DDCCIScreen: Identifiable,Equatable,Hashable {
    var id: Int
    var name: String
    var brightness: Int
    var powerState: String
}

class DDCCIScreenModel: ObservableObject {
    @Published var ddcciscreens = [DDCCIScreen]();
    
    init() {
        ddcciscreens = DDCCI.externalScreens();
    }
    
    func update(for screen: DDCCIScreen, to newScreen: DDCCIScreen) {
        if let index = ddcciscreens.firstIndex(where: { $0.id == screen.id }) {
            ddcciscreens[index] = newScreen;
        }
    }
    func updateBrightness(for screenId: Int, to brightness: Int) {
        if let index = ddcciscreens.firstIndex(where: { $0.id == screenId }) {
            ddcciscreens[index].brightness = brightness;
        }
    }
    func togglePower(for screenId: Int, previousState powerState: String) {
        if let index = ddcciscreens.firstIndex(where: { $0.id == screenId }) {
            ddcciscreens[index].powerState = ddcciscreens[index].powerState == "on" ? "off" : "on";
        }
    }
}

class DDCCI {
    
    class func getDisplayDeviceLocation(cdisplay: CGDirectDisplayID) -> String? {
        let wsPrefs: String = "/Library/Preferences/com.apple.windowserver.plist";
        let wsDict = NSDictionary(contentsOfFile: wsPrefs);
        if (wsDict == nil) {
            print("Failed to parse \(wsPrefs)")
            return nil;
        }
        let wsDisplaySets = wsDict?.value(forKey: "DisplayAnyUserSets");
        if (wsDisplaySets == nil) {
            print("Failed to get 'DisplayAnyUserSets' from WindoServer preferences");
            return nil;
        }
        
        for displaySet in (wsDisplaySets as! NSArray) {
            for display in (displaySet as! [NSDictionary]) {
                if(display.value(forKey: "DisplayID") as! UInt32 == cdisplay){
                    return display.value(forKey: "IODisplayLocation") as? String;
                }
            }
        }
        
        return nil;
    }
    
    class func getFrameBuffer(screenId: UInt32) -> io_service_t {
        var framebuffer: io_service_t = 0;
        let devLoc: String? = getDisplayDeviceLocation(cdisplay: screenId);
        
        if (framebuffer == 0 && devLoc == nil) {
            print("Failed to get framebuffer for current display.");
        }
        
        if (framebuffer == 0 && devLoc != nil) {
            framebuffer = IOFramebufferPortFromCGDisplayID(screenId, (devLoc! as CFString));
        }
        return framebuffer;
    }
    
    class func getControl(screenId: UInt32, controlId: UInt8) -> Int {
        var command: DDCReadCommand = DDCReadCommand();
        command.control_id = controlId;
        command.max_value = 0;
        command.current_value = 0;
        
        if (!DDCRead(screenId, &command)) {
            print("DDC read command failed")
        }
        return Int(command.current_value);
    }
    
    class func setControl(framebuffer: io_service_t, controlId: UInt8, newValue: UInt8) -> Void {
        var command: DDCWriteCommand = DDCWriteCommand();
        command.control_id = controlId;
        command.new_value = newValue;
        
        if (!DDCWrite(framebuffer, &command)) {
            print("Failed to write DDC command \(controlId)");
        }
    }
    
    class func setBrightness(screenId: UInt32, brightness: UInt8) -> Void {
        let framebuffer: io_service_t = getFrameBuffer(screenId: screenId);
        var brightnessSet = brightness;
        if (brightnessSet > 100) {brightnessSet = 100};
        setControl(framebuffer: framebuffer, controlId: UInt8(BRIGHTNESS), newValue: brightnessSet);
    }
    
    class func getBrightness(screenId: UInt32) -> Int {
        let framebuffer: io_service_t = getFrameBuffer(screenId: screenId);
        let brightness: Int = getControl(screenId: framebuffer, controlId: UInt8(BRIGHTNESS));
        return brightness;
    }
    
    class func setPowerState(screenId: UInt32, powerState: UInt8) -> Void {
        DispatchQueue.main.async {
        let framebuffer: io_service_t = getFrameBuffer(screenId: screenId);
        var powerSet = powerState;
        if (powerSet < 1) {powerSet = 1};
        if (powerSet > 5) {powerSet = 5};
            setControl(framebuffer: framebuffer, controlId: UInt8(DPMS), newValue: powerSet);
        }
    }
    
    class func getPowerState(screenId: UInt32) -> Int {
        let framebuffer: io_service_t = getFrameBuffer(screenId: screenId);
        let powerState: Int = getControl(screenId: framebuffer, controlId: UInt8(DPMS));
        return powerState;
    }
    
    class func externalScreens() -> [DDCCIScreen] {
        let screens = NSScreen.screens;
        let description: NSDeviceDescriptionKey = NSDeviceDescriptionKey(rawValue: "NSScreenNumber")
        
        var returnValue: [DDCCIScreen] = [];
        for screen in screens {
            let name = screen.localizedName;
            let deviceID = screen.deviceDescription[description] as! Int
            let brightness = getBrightness(screenId: UInt32(deviceID));
            let powerState = getPowerState(screenId: UInt32(deviceID));
            returnValue.append(DDCCIScreen(id: deviceID, name: name, brightness: brightness, powerState: powerState == 1 ? "on":"off"))
        }
        return returnValue;
    }
}

