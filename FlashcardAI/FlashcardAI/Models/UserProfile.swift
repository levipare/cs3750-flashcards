//
//  UserProfile.swift
//  FlashcardAI
//
//  Created by Surya Malik on 10/16.
//

import Foundation
import FirebaseFirestore

struct UserProfile: Identifiable, Codable {
    @DocumentID var id: String?          // Firebase UID
    var email: String
    var displayName: String
    var createdAt: Date
    var lastLogin: Date?
    var photoURL: String?
    var role: String                     // e.g. “student”, “educator”, “admin”
    var deckCount: Int                   // how many decks user has created

    init(
        id: String? = nil,
        email: String,
        displayName: String,
        createdAt: Date = Date(),
        lastLogin: Date? = nil,
        photoURL: String? = nil,
        role: String = "student",
        deckCount: Int = 0
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
        self.lastLogin = lastLogin
        self.photoURL = photoURL
        self.role = role
        self.deckCount = deckCount
    }
}
