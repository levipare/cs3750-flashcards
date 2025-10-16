//
//  AuthView.swift
//  FlashcardAI
//
//  Created by Surya Malik on 10/16/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var userData: [String: Any] = [:]

    private let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 16) {
            // App title
            Text("Welcome to FlashcardAI")
                .font(.title2)
                .bold()
                .padding(.bottom, 10)

            // Email field
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding(.horizontal)

            // Password field
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            // Sign Up button
            Button("Sign Up") {
                signUp()
            }
            .buttonStyle(.borderedProminent)

            // Sign In button
            Button("Sign In") {
                signIn()
            }
            .buttonStyle(.bordered)

            Divider().padding(.vertical, 8)

            // Message area
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            // Firestore sanity check display
            if !userData.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Firestore data:")
                        .font(.subheadline)
                        .bold()
                    ForEach(userData.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        Text("\(key): \(String(describing: value))")
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top, 40)
        .onAppear {
            if let user = Auth.auth().currentUser {
                message = "Already signed in as \(user.email ?? "")"
                fetchUserData(for: user)
            }
        }
    }

    // MARK: - Firebase Functions

    private func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                message = "❌ Sign up failed: \(error.localizedDescription)"
            } else if let user = result?.user {
                message = "✅ Signed up as \(user.email ?? "")"
                saveUserData(for: user)
            }
        }
    }

    private func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                message = "❌ Sign in failed: \(error.localizedDescription)"
            } else if let user = result?.user {
                message = "✅ Signed in as \(user.email ?? "")"
                fetchUserData(for: user)
            }
        }
    }

    private func saveUserData(for user: User) {
        let docRef = db.collection("users").document(user.uid)
        let data: [String: Any] = [
            "email": user.email ?? "",
            "createdAt": Timestamp(date: Date())
        ]
        docRef.setData(data) { error in
            if let error = error {
                message = "⚠️ Error saving user: \(error.localizedDescription)"
            } else {
                message += "\nSaved to Firestore ✅"
                fetchUserData(for: user)
            }
        }
    }

    private func fetchUserData(for user: User) {
        let docRef = db.collection("users").document(user.uid)
        docRef.getDocument { snapshot, error in
            if let error = error {
                message = "⚠️ Fetch failed: \(error.localizedDescription)"
            } else if let data = snapshot?.data() {
                userData = data
                message += "\nFetched Firestore data ✅"
            } else {
                message += "\nNo Firestore data found ⚠️"
            }
        }
    }
}

#Preview {
    AuthView()
}
