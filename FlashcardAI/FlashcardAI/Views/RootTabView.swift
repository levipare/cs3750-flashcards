//
//  RootTabView.swift
//  FlashcardAI
//
//  Created by River Bumpas on 10/15/25.
//
import SwiftUI

struct RootTabView: View {
    enum Tab { case home, camera }
    @State private var selection: Tab = .home
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                SplashView(openCamera: { selection = .camera })
                    .tabItem { Label("Home", systemImage: "house") }
                    .tag(Tab.home)

                UploadImagesView()
                    .tabItem { Label("Camera", systemImage: "camera") }
                    .tag(Tab.camera)
            }
            .navigationTitle("FlashcardAI")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        authViewModel.signOut()
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}
