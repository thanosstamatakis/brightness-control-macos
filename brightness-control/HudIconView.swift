//
//  HudIconView.swift
//  brightness-control
//
//  Created by Thanos Stamatakis on 9/11/21.
//

import SwiftUI

struct HudIconView: View {
    var iconName: String = "tv";
    var body: some View {
        ZStack{
            EffectsView(material: NSVisualEffectView.Material.hudWindow, blendingMode: NSVisualEffectView.BlendingMode.behindWindow)
                .frame(width: 200, height: 200)
                .cornerRadius(20)
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .allowsTightening(false)
                .font(.system(size: 16, weight: .light))
                .frame(width: 115, height: 115)
                .foregroundColor(Color(NSColor.controlTextColor).opacity(0.85))
                .offset(x: 0, y: 0)
        }.cornerRadius(20.0)
        .frame(width: 200, height: 200)
    }
}

struct HudIconView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
             HudIconView().preferredColorScheme($0)
        }
    }
}
