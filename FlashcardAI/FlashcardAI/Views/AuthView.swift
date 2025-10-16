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
    @State private var signUpAttempted = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome to FlashcardAI")
                .font(.title2)
                .bold()
                .padding(.bottom, 10)

            TextField("Full Name", text: $displayName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .overlay(
                    signUpAttempted ? RoundedRectangle(cornerRadius: 8)
                        .stroke(isValidName(displayName) || displayName.count == 0 ? Color.clear : Color.red, lineWidth: 2).padding(.horizontal) : nil
                )

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding(.horizontal)
                .overlay(
                        signUpAttempted ? RoundedRectangle(cornerRadius: 8)
                            .stroke(isValidEmail(email) || email.count == 0 ? .clear : .red, lineWidth: 2).padding(.horizontal) : nil
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
                        signUpAttempted ? RoundedRectangle(cornerRadius: 8)
                            .stroke(pwOverlayColor, lineWidth: 2).padding(.horizontal) : nil
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
                        signUpAttempted = true
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

func isValidName(_ name: String) -> Bool {
    let parts = name.split(separator: " ")
    return parts.count >= 2 && parts.allSatisfy { part in
        return !part.isEmpty
    }
}

func isValidEmail(_ email: String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

    let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: email)
}

func getPasswordStrength(_ pw: String) -> Int {
    let hasUppercase : Bool = pw.range(of: "[A-Z]", options: .regularExpression) != nil
    let hasLowercase : Bool = pw.range(of: "[a-z]", options: .regularExpression) != nil
    let hasNumber : Bool = pw.range(of: "[0-9]", options: .regularExpression) != nil
    let hasSpecial : Bool = pw.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        
    let features = [hasUppercase, hasLowercase, hasNumber, hasSpecial].filter { feature in feature }.count
        
    if pw.count >= 10 && features == 4 {
        return 2
    } else if pw.count >= 8 && features >= 2 {
        return 1
    } else {
        return 0
    }
}

//#Preview {
//    ContentView()
//}

