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
        VStack {
            Spacer().frame(height: 40)

        
            Toggle(isOn: $settings.darkModeToggleState) {
                Text("Dark Mode")
                    .font(.headline)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)

            Spacer()

            Button {
                authViewModel.signOut()
            } label: {
                Text("Sign Out")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.red)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            Spacer().frame(height: 50)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Settings")
    }
}

