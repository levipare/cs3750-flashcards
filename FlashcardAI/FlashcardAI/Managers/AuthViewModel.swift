//
//  AuthViewModel.swift
//  FlashcardAI
//
//  Created by Surya Malik on 10/16/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var userProfile: UserProfile?

    private var handle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        self.user = Auth.auth().currentUser
        listenToAuthChanges()
    }

    private func listenToAuthChanges() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.user = user
            Task {
                if let user = user {
                    await self.fetchUserProfile(for: user.uid)
                } else {
                    self.userProfile = nil
                }
            }
        }
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let user = result.user
        try await saveUserProfile(for: user, displayName: displayName)
        self.user = user
    }

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        self.user = result.user
        await fetchUserProfile(for: result.user.uid)

        // Update last login timestamp
        let ref = db.collection("users").document(result.user.uid)
        try await ref.updateData(["lastLogin": Date()])
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.userProfile = nil
        } catch {
            print("Sign out failed: \(error.localizedDescription)")
        }
    }

    private func saveUserProfile(for user: User, displayName: String) async throws {
        let profile = UserProfile(
            id: user.uid,
            email: user.email ?? "",
            displayName: displayName,
            createdAt: Date(),
            lastLogin: Date(),
            role: "student",
            deckCount: 0
        )
        try db.collection("users").document(user.uid).setData(from: profile)
        self.userProfile = profile
    }

    private func fetchUserProfile(for uid: String) async {
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            self.userProfile = try snapshot.data(as: UserProfile.self)
        } catch {
            print("Failed to fetch profile:", error.localizedDescription)
        }
    }
}
