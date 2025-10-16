//
//  AuthView.swift
//  FlashcardAI
//
//  Created by Surya Malik on 10/16/25.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var message = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome to FlashcardAI")
                .font(.title2)
                .bold()
                .padding(.bottom, 10)

            TextField("Full Name", text: $displayName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding(.horizontal)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            Button("Sign Up") {
                Task {
                    do {
                        try await authVM.signUp(email: email, password: password, displayName: displayName)
                        message = "Signed up successfully as \(email)"
                    } catch {
                        message = "Sign up failed: \(error.localizedDescription)"
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Sign In") {
                Task {
                    do {
                        try await authVM.signIn(email: email, password: password)
                        message = "Signed in successfully as \(email)"
                    } catch {
                        message = "Sign in failed: \(error.localizedDescription)"
                    }
                }
            }
            .buttonStyle(.bordered)

            Divider().padding(.vertical, 8)

            if let profile = authVM.userProfile {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Firestore Profile:")
                        .font(.subheadline)
                        .bold()
                    Text("Email: \(profile.email)")
                    Text("Display Name: \(profile.displayName)")
                    Text("Role: \(profile.role)")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .padding(.horizontal)
            }

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 40)
    }
}

//#Preview {
//    ContentView()
//}
