//
//  FlashcardAIApp.swift
//  FlashcardAI
//
//  Created by River Bumpas on 10/15/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct FlashcardAIApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var settings = Settings()
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.user != nil {
                DecksView().environmentObject(authViewModel).environmentObject(settings).environment(\.colorScheme, settings.colorScheme)
            } else {
                AuthView().environmentObject(authViewModel)
            }
        }
    }
}
