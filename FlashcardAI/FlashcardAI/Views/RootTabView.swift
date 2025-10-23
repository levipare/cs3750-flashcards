//
//  RootTabView.swift
//  FlashcardAI
//
//  Created by River Bumpas on 10/15/25.
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                SplashView()
            }
            
            Tab("Decks", systemImage: "square.stack.3d.up") {
                DecksView()
            }
            
            Tab("Scan", systemImage: "camera") {
                UploadImagesView()
            }
            
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}
