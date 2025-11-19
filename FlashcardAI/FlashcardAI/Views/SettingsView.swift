//
//  SettingsView.swift
//  FlashcardAI
//
//  Created by Levi Pare on 10/16/25.
//

import FirebaseAuth
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("Display name:").font(.system(size: 16))
                    Spacer()
                }.padding(.horizontal)
                HStack {
                    Text(authViewModel.userProfile?.displayName ?? "").font(
                        .system(size: 32)
                    )
                    Spacer()
                    //                Image(systemName: "pencil")
                    //                    .foregroundColor(.primary)
                    //                    .font(.system(size: 36))
                }.padding(.horizontal)
                    .padding(.bottom)

                HStack {
                    Text("Current email:").font(.system(size: 16))
                    Spacer()
                }.padding(.horizontal)
                HStack {
                    Text(authViewModel.userProfile?.email ?? "").font(
                        .system(size: 24)
                    )
                    Spacer()
                    //                Image(systemName: "pencil")
                    //                    .foregroundColor(.primary)
                    //                    .font(.system(size: 36))
                }.padding(.horizontal)

                Spacer()

            }.task {
                await authViewModel.fetchUserProfile(
                    for: Auth.auth().currentUser?.uid ?? ""
                )
            }
            .padding()

            Spacer()

            Button {
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
