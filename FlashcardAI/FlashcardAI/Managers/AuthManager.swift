//
//  AuthManager.swift
//  FlashcardAI
//
//  Created by Surya Malik on 10/15/25.
//

@preconcurrency import FirebaseAuth

// Suppress sendable??
@MainActor
class AuthManager: ObservableObject {
    @Published var user: User?

    init() {
        self.user = Auth.auth().currentUser
    }

    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        DispatchQueue.main.async {
            self.user = result.user
        }
    }

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        DispatchQueue.main.async {
            self.user = result.user
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
        DispatchQueue.main.async {
            self.user = nil
        }
    }
}
