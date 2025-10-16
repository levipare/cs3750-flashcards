//
//  AuthView.swift
//  FlashcardAI
//
//  Created by Surya Malik on 10/16/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var userData: [String: Any] = [:]

    private let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 12) {
            // Email + Password fields
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .padding(.horizontal)
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            // Sign Up button
            Button("Sign Up") {
                Auth.auth().createUser(withEmail: email, password: password) { result, error in
                    if let error = error {
                        message = "Sign up failed: \(error.localizedDescription)"
                    } else if let user = result?.user {
                        message = "Signed up as \(user.email ?? "")"
                        saveUserData(for: user)
                    }
                }
            }

            // Sign In button
            Button("Sign In") {
                Auth.auth().signIn(withEmail: email, password: password) { result, error in
                    if let error = error {
                        message = "Sign in failed: \(error.localizedDescription)"
                    } else if let user = result?.user {
                        message = "Signed in as \(user.email ?? "")"
                        fetchUserData(for: user)
                    }
                }
            }

            // Sign Out button
            Button("Sign Out") {
                do {
                    try Auth.auth().signOut()
                    message = "Signed out"
                    userData = [:]
                } catch {
                    message = "Sign out failed: \(error.localizedDescription)"
                }
            }

            Divider().padding(.vertical, 10)

            // Display messages + user data
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.bottom, 6)

            if !userData.isEmpty {
                VStack(alignment: .leading) {
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
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
        .padding()
        .onAppear {
            if let user = Auth.auth().currentUser {
                message = "Already signed in as \(user.email ?? "")"
                fetchUserData(for: user)
            }
        }
    }

    // Save minimal data to Firestore
    private func saveUserData(for user: User) {
        let docRef = db.collection("users").document(user.uid)
        let data: [String: Any] = [
            "email": user.email ?? "",
            "createdAt": Timestamp(date: Date())
        ]
        docRef.setData(data) { error in
            if let error = error {
                message = "Error saving user: \(error.localizedDescription)"
            } else {
                message += "\nSaved to Firestore"
                fetchUserData(for: user)
            }
        }
    }

    // Fetch from Firestore for sanity check
    private func fetchUserData(for user: User) {
        let docRef = db.collection("users").document(user.uid)
        docRef.getDocument { snapshot, error in
            if let error = error {
                message = "Fetch failed: \(error.localizedDescription)"
            } else if let data = snapshot?.data() {
                userData = data
                message += "\nFetched Firestore data"
            } else {
                message += "\nNo Firestore data found"
            }
        }
    }
}

//#Preview {
//    ContentView()
//}
