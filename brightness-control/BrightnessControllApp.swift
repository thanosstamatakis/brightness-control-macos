//
//  BrightnessControllApp.swift
//  brightness-control
//
//  Created by Thanos Stamatakis on 2/11/21.
//

import SwiftUI

@main
struct BrightnessControllApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate;
    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
        Settings {
            ContentView()
        }
    }
}

extension NSScreen {
    struct ExternalScreen: Identifiable,Equatable {
        var id: Int
        var name: String
        var brightness: Int
        var powerState: String
    }
    
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
        let devLoc: String? = NSScreen.getDisplayDeviceLocation(cdisplay: screenId);
        
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
        let framebuffer: io_service_t = getFrameBuffer(screenId: screenId);
        var powerSet = powerState;
        if (powerSet < 1) {powerSet = 1};
        if (powerSet > 5) {powerSet = 5};
        setControl(framebuffer: framebuffer, controlId: UInt8(DPMS), newValue: powerSet);
    }
    
    class func getPowerState(screenId: UInt32) -> Int {
        let framebuffer: io_service_t = getFrameBuffer(screenId: screenId);
        let powerState: Int = getControl(screenId: framebuffer, controlId: UInt8(DPMS));
        return powerState;
    }
    
    class func externalScreens() -> [ExternalScreen] {
        let screens = NSScreen.screens;
        let description: NSDeviceDescriptionKey = NSDeviceDescriptionKey(rawValue: "NSScreenNumber")
        
        var returnValue: [ExternalScreen] = [];
        for screen in screens {
//            print(screen.visibleFrame.origin.x)
            let name = screen.localizedName;
            let deviceID = screen.deviceDescription[description] as! Int
            let brightness = getBrightness(screenId: UInt32(deviceID));
            let powerState = getPowerState(screenId: UInt32(deviceID));
            returnValue.append(ExternalScreen(id: deviceID, name: name, brightness: brightness, powerState: powerState == 1 ? "on":"off"))
        }
        return returnValue;
    }
}

class AppDelegate: NSObject,NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popOver: NSPopover!
    
    
    func applicationDidFinishLaunching(_ notification: Notification){
        let contentView = ContentView()
        let popOver = NSPopover()
        popOver.behavior = .transient
        popOver.animates = true
        popOver.contentViewController = NSHostingController(rootView: contentView)
        popOver.setValue(true, forKeyPath: "shouldHideAnchor")
        
        self.popOver = popOver
        self.statusItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        
        if let MenuButton = self.statusItem.button {
            MenuButton.image = NSImage(systemSymbolName: "display.2", accessibilityDescription: nil)
            MenuButton.action = #selector(MenuButtonToggle)
        }
    }
    
    @objc func MenuButtonToggle(_ sender: AnyObject){
        if let button = self.statusItem.button {
            if self.popOver.isShown{
                self.popOver.performClose(sender)
            }else {
                self.popOver.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                self.popOver.contentViewController?.view.window?.makeKey()

            }
        }
    }
}

