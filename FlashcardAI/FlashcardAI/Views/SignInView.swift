//
//  SignInView.swift
//  FlashcardAI
//
//  Created by Daniel Eror on 10/30/25.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var message = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Welcome Back to FlashcardAI")
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 10)
                
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
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
                .buttonStyle(.borderedProminent)
                
                Text("Don't have an account?").padding(.bottom, 0)
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Text("Go Back")
                    }
                    Text("to sign up.")
                    Spacer()
                }.padding(.top, 0)
                
                Divider().padding(.vertical, 8)
                
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationBarBackButtonHidden()
        }
    }
}
