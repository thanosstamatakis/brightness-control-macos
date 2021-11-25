//
//  CustomWindow.swift
//  brightness-control
//
//  Created by Thanos Stamatakis on 8/11/21.
//
import Foundation
import AppKit
import SwiftUI

class CustomWindow: NSWindow {
    private var side = 200.0;
    private let mainScreenWidth = NSScreen.main!.frame.width;
    private let mainScreenHeight = NSScreen.main!.frame.height;
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: bufferingType, defer: flag)
        self.contentView = NSHostingView(rootView: HudIconView());
        self.setContentSize(NSSize(width: side, height: side));
        self.setFrameOrigin(NSPoint(x: (mainScreenWidth/2)-(CGFloat(side)/2), y: mainScreenHeight*0.097222222));
        self.alphaValue=0
        self.hasShadow = false
        self.title = "My Custom Title"
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.styleMask = .docModalWindow
        self.isMovable = false
        self.collectionBehavior = [.canJoinAllSpaces,.stationary]
        self.orderFrontRegardless()
        self.ignoresMouseEvents = true
        self.level = .floating
        self.unregisterDraggedTypes()
    }
    
    class func getHud()->CustomWindow?{
        for win in NSApp.windows {
            if win.className.contains("CustomWindow") {
                return win as! CustomWindow;
            }
        }
        return nil;
    }
    
    func setIcon(iconName: String) -> Void {
        let view = HudIconView(iconName: iconName);
        self.contentView = NSHostingView(rootView: view);
    }
    
    func showHud(icon:String){
        self.setIcon(iconName: icon);
        self.alphaValue = 1;
        self.contentView?.layer?.removeAllAnimations();
        self.alphaValue = 1;
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 1;
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self.animator().alphaValue = 0;
            } completionHandler: {
                //Do something
            }
        })
    }
}
