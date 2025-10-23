//
//  SettingsView.swift
//  FlashcardAI
//
//  Created by Levi Pare on 10/16/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        VStack{
            Spacer()
            Toggle(isOn: $settings.darkModeToggleState)
            {Text("Dark Mode")}.padding()
            Spacer()
            Button("Sign Out") {
                authViewModel.signOut()
            }
            .foregroundColor(.red)
            Spacer()
        }
    }
}
