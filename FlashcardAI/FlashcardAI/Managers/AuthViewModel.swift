//
//  AuthViewModel.swift
//  FlashcardAI
//
//  Created by Surya Malik on 10/16/25.
//

import Foundation
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User? = nil
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        self.user = Auth.auth().currentUser
        listenToAuthChanges()
    }

    private func listenToAuthChanges() {
        // Store the handle so it isn’t unused
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
            self.user = user
        }
    }

    deinit {
        // Remove the listener when the view model is destroyed
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Sign out failed: \(error.localizedDescription)")
        }
    }
}
