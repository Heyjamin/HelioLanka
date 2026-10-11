//
//  ContentView.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-11.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
       
        ZStack {
            HelioBackground()
            
            VStack(spacing:16){
                Text("HelioLanka")
                    .font(.system(size:40, weight:.bold, design:.rounded))
                    .foregroundStyle(HelioTheme.navy)
                
                Text ("Your rooftop solar, elevated.")
                    .font(.title3)
                    .foregroundStyle(HelioTheme.inkMuted)
                    .multilineTextAlignment(.center)
                
                Text("Phase 01 complete")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(HelioTheme.ocean)
                    .padding(.top,24)
            }
            .padding(HelioTheme.screenPadding)
        }
        
    }
    
}

#Preview {
    ContentView()
}
