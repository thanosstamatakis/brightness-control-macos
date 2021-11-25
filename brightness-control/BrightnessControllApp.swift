//
//  BrightnessControllApp.swift
//  brightness-control
//
//  Created by Thanos Stamatakis on 2/11/21.
//

import SwiftUI
import Combine
import Cocoa

@main
struct BrightnessControllApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate;
    var body: some Scene {
        Settings {
            ContentView()
        }
    }
}

class AppDelegate: NSObject,NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popOver: NSPopover!
    var windowRef = CustomWindow();
    var contextWin =  NSWindow();
    @ObservedObject var screenModel = DDCCIScreenModel();

    func applicationDidFinishLaunching(_ notification: Notification){
        let contentView = ContentView().environmentObject(self.screenModel);
        let popOver = NSPopover();

        popOver.behavior = .transient
        popOver.animates = true
        popOver.contentViewController = NSHostingController(rootView: contentView)
        popOver.setValue(true, forKeyPath: "shouldHideAnchor")
        
        
        self.contextWin.setContentSize(NSSize(width: 200, height: 1));
        self.contextWin.alphaValue=1
        self.contextWin.hasShadow = false
        self.contextWin.title = "My Custom Title"
        self.contextWin.titleVisibility = .hidden
        self.contextWin.titlebarAppearsTransparent = true
        self.contextWin.isOpaque = true
        self.contextWin.backgroundColor = NSColor.clear
        self.contextWin.styleMask = .docModalWindow
        self.contextWin.isMovable = false
        self.contextWin.collectionBehavior = [.canJoinAllSpaces,.stationary]
        self.contextWin.orderFrontRegardless()
        self.contextWin.ignoresMouseEvents = true
        self.contextWin.level = .floating
        self.contextWin.unregisterDraggedTypes()


        self.popOver = popOver
        self.statusItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength));

        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            print("Access Not Enabled")
        }

        if checkAccess() {
            Tap(screenModel: screenModel);
        } else {
            print("Enable access in System Preferences, then rerun.")
        }

        if let MenuButton = self.statusItem.button {
            MenuButton.image = NSImage(systemSymbolName: "tv", accessibilityDescription: nil)
            MenuButton.action = #selector(MenuButtonToggle)
        }
        
    }

    @objc func MenuButtonToggle(_ sender: AnyObject){
        if let button = self.statusItem.button {
            if self.popOver.isShown{
                self.popOver.performClose(sender)
            }else {
                NSApplication.shared.activate(ignoringOtherApps: true)
                let buttonRect:NSRect = button.convert(button.bounds, to: nil);
                let screenRect:NSRect = button.window!.convertToScreen(buttonRect);
                let posX = screenRect.origin.x;
                let posY = screenRect.origin.y + 20;
                self.contextWin.setFrameOrigin(NSPoint(x: posX, y: posY))
                self.popOver.show(relativeTo: self.contextWin.contentView!.frame, of: self.contextWin.contentView!, preferredEdge: NSRectEdge.minX)
                self.popOver.contentViewController?.view.window?.makeKey();
            }
        }
    }
}
