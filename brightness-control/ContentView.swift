//
//  ContentView.swift
//  brightness-control
//
//  Created by Thanos Stamatakis on 2/11/21.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State var perc: Int = 0;
    @State var screens = NSScreen.externalScreens();
    var body: some View {
//        VStack() {
//            ForEach(screens, id: \.self.id) { screen in
//                Module(percentage: $perc, title: screen.name,)
//            }
//        }.padding(10)
//        .frame(width: 300)
//        .fixedSize(horizontal: false, vertical: true)
        VStack() {
            ForEach(screens.indices, id: \.self) {
                Module(percentage: self.$screens[$0].brightness, title: self.$screens[$0].name, id: self.$screens[$0].id)
            }
        }.padding(10)
        .frame(width: 300)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct Module: View {
    @Binding var percentage: Int;
    @Binding var title: String;
    @Binding var id: Int;
    
    var body: some View {
        ZStack(){
            VStack (alignment: .leading) {
                Text(title).font(.headline)
                Slider(percentage: $percentage, id: $id)
            }
            .padding(10)
            
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5, antialiased: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                .padding(1)
                
        }.fixedSize(horizontal: false, vertical: true)
        .border(Color.black.opacity(0.3))
        .background(Color.black.opacity(0.15))
        .cornerRadius(10)
        .shadow(color: .black, radius: 125, x: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, y: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/)
        
    }
}

struct Slider: View {
    @Binding var percentage: Int
    @Binding var id: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(minWidth: 100, idealWidth: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealHeight: 22, maxHeight: 22, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    .cornerRadius(15.0)
                    .shadow(radius: 1)
                    .foregroundColor(Color(NSColor.disabledControlTextColor))
                Rectangle()
                    .foregroundColor(percentage<8 ? .white.opacity(0) : .white)
                    .frame(width: geometry.size.width * CGFloat(self.percentage)/100, height: 22.0)
                    .cornerRadius(15.0)
                Circle()
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                    .frame(width: CGFloat(22.0), height: CGFloat(22.0))
                    .offset(x: self.percentage > 8 ? (geometry.size.width * CGFloat(self.percentage) / 100 - 22): 0, y: 0)
//                    let _ = print(CGFloat(Int(self.percentage))/100)
                Image(systemName: self.percentage == 0 ?
                        "sun.max" : "sun.max.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(Color(NSColor.gray))
                    .offset(x: 4, y: 0)
                    .allowsHitTesting(false)
            }.gesture(DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            self.percentage = Int(min(max(0, Float(value.location.x / geometry.size.width * 100)), 100));
                        }.onEnded { _ in
                            print("Would send ddcci perc of: \(self.percentage) for id:\(id)");
                            NSScreen.setBrightness(screenId: UInt32(id), brightness: UInt8(self.percentage));
                        })
        }.frame(height:22)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            
            
    }
}
