//
//  ContentView.swift
//  brightness-control
//
//  Created by Thanos Stamatakis on 2/11/21.
//

import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var screenModel:DDCCIScreenModel;
    var body: some View {
        ZStack {
            EffectsView(material: NSVisualEffectView.Material.popover, blendingMode: NSVisualEffectView.BlendingMode.behindWindow)
            VStack() {
                
                ForEach(screenModel.ddcciscreens) { screen in
                    Module(screen: screen).environmentObject(self.screenModel)
                }
            }.padding(10)
            .frame(width: 300)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// blur effect
struct EffectsView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = NSVisualEffectView.State.active
        return visualEffectView
    }

    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

struct Module: View {
    var screen: DDCCIScreen;
    @EnvironmentObject var screenModel: DDCCIScreenModel;
    @Environment(\.colorScheme) var colorScheme
    let concurrentQueue = DispatchQueue(label: "brightness.queue", attributes: .concurrent);

    var body: some View {
        var hud = CustomWindow.getHud();
        ZStack(){
            VStack (alignment: .leading, spacing: 0) {
                Text(screen.name).font(.system(size: 11, weight: .semibold))
                    .padding(.bottom, 3)
                HStack (alignment: .center){
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle().frame(minWidth: 100, idealWidth: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealHeight: 22, maxHeight: 22, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                                .cornerRadius(15.0)
                                .foregroundColor(colorScheme == .light  ? Color(.gray).opacity(0.1): .white.opacity(0.2))
                            Rectangle()
                                .foregroundColor(self.screen.brightness<8 ? .white.opacity(0) : .white)
                                .frame(width: geometry.size.width * CGFloat(self.screen.brightness)/100, height: 22.0)
                                .cornerRadius(15.0)
                            Circle()
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                                .frame(width: CGFloat(22.0), height: CGFloat(22.0))
                                .offset(x: self.screen.brightness > 8 ? (geometry.size.width * CGFloat(self.screen.brightness) / 100 - 22): 0, y: 0)
                            if (colorScheme == .light) {
                            RoundedRectangle(cornerRadius: 15)
                                .strokeBorder(Color(.gray).opacity(0.5), lineWidth: 1, antialiased: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                                .frame(minWidth: 100, idealWidth: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: 22, idealHeight: 22, maxHeight: 22, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                            }
                            Image(systemName: self.screen.brightness == 0 ?
                                    "sun.max" : "sun.max.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundColor(Color(NSColor.gray))
                                .offset(x: 4, y: 0)
                                .allowsHitTesting(false)
                        }
                        .gesture(DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let val = Int(min(max(0, Float(value.location.x / geometry.size.width * 100)), 100));
                                        screenModel.update(for: screen, to: DDCCIScreen(id: screen.id, name: screen.name, brightness: val, powerState: screen.powerState))
                                            show_blur_hud(UInt32(screen.id),Int32(val));
                                    }.onEnded { _ in
                                        DDCCI.setBrightness(screenId: UInt32(screen.id), brightness: UInt8(screen.brightness));
                                    })
                    }
                    .frame(height:22)
                    .cornerRadius(15)
                    .mask(
                        Rectangle()
                            .background(Color(.red))
                            .cornerRadius(16)
                            .frame(minWidth: 100, idealWidth: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealHeight: 22, maxHeight: 22, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    )
                    Ellipse()
                        .foregroundColor(screen.powerState == "on" ? Color(NSColor.controlAccentColor) : Color(NSColor.disabledControlTextColor).opacity(0.8))
                        .overlay(
                            Image(systemName: "tv")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .allowsHitTesting(false)
                                .padding(5)
                                .foregroundColor(screen.powerState == "off" ? Color(NSColor.controlTextColor) : .white)
                                .font(.system(size: 16, weight: .regular))
                        )
                        .frame(width: 26, height: 26)
                        .onTapGesture() {
                            DDCCI.setPowerState(screenId: UInt32(screen.id), powerState: screen.powerState == "on" ? 4:1);
                            hud?.showHud(icon: screen.powerState == "on" ? "tv":"tv.fill");
                            screenModel.togglePower(for: screen.id, previousState: screen.powerState);
                        }
                }
            }
            .padding(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))
            if (colorScheme == .dark) {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5, antialiased: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                    .padding(1)
            }
            
        }.fixedSize(horizontal: false, vertical: true)
        .border(Color.black.opacity(colorScheme == .dark ? 0.3 : 0))
//        .background(colorScheme == .dark ? Color.black.opacity(0.15) : Color.white.opacity(0.35))
        .background(EffectsView(material: NSVisualEffectView.Material.popover, blendingMode: NSVisualEffectView.BlendingMode.withinWindow))
        .cornerRadius(10)
        .shadow( color: .black.opacity(0.1),radius: 8, x: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, y: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/)
        
    }
}

struct PreviewWrapper: View {
    @ObservedObject var screenModel = DDCCIScreenModel();
    
    var body: some View {
        ContentView().environmentObject(screenModel);
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
             PreviewWrapper().preferredColorScheme($0)
        }
    }
}
