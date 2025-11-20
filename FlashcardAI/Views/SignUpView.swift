//
//  SignUpView.swift
//  FlashcardAI
//
//  Created by Daniel Eror on 10/30/25.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var message = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Welcome to FlashcardAI")
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 10)
                
                TextField("Full Name", text: $displayName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(isValidName(displayName) || displayName.count == 0 ? Color.clear : Color.red, lineWidth: 2).padding(.horizontal)
                    )
                
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isValidEmail(email) || email.count == 0 ? .clear : .red, lineWidth: 2).padding(.horizontal)
                    )
                
                let strength = getPasswordStrength(password)
                let pwOverlayColor: Color = {
                    if password.isEmpty{
                        return .clear
                    }
                    if strength == 0{
                        return .red
                    }
                    if strength == 1{
                        return .yellow
                    }
                    else{
                        return .green
                    }
                }()
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(pwOverlayColor, lineWidth: 2).padding(.horizontal)
                    )
                
                Button("Sign Up") {
                    Task {
                        if isValidName(displayName) && isValidEmail(email) && getPasswordStrength(password) == 2 {
                            do {
                                try await authVM.signUp(email: email, password: password, displayName: displayName)
                                message = "Signed up successfully as \(email)"
                            } catch {
                                message = "Sign up failed: \(error.localizedDescription)"
                            }
                        }
                        else{
                            message = "Sign up failed!\nPlease ensure you enter a valid name, email, and strong password.\nPassword must include the following:\n\t10+ characters\n\tupper and lower case letters\n\tat least one number\n\tat least one special character"
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Text("Already have an account?").padding(.bottom, 0)
                HStack {
                    Spacer()
                    NavigationLink(destination: SignInView()) {
                        Text("Click Here")
                    }
                    Text("to sign in.")
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
