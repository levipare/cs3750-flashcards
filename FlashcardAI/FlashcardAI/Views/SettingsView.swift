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
        VStack {
            Spacer()

            Button{
                authViewModel.signOut()
            } label: {
                Text("Sign Out").frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding()
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
