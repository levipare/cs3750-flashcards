//
//  SettingsView.swift
//  FlashcardAI
//
//  Created by Levi Pare on 10/16/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Button("Sign Out") {
            authViewModel.signOut()
        }
        .foregroundColor(.red)
    }
}
