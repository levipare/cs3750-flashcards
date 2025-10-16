//
//  FirestoreManager.swift
//  FlashcardAI
//
//  Created by Surya Malik on 10/15/25.
//

import FirebaseFirestore

struct Flashcard: Identifiable, Codable {
    @DocumentID var id: String?
    var frontText: String
    var backText: String
    var order: Int
}

struct Deck: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var ownerID: String
    var shareCode: String?
}

class FirestoreManager {
    private let db = Firestore.firestore()

    func addDeck(_ deck: Deck) async throws {
        try db.collection("decks").addDocument(from: deck)
    }

    func fetchDecks(for userID: String) async throws -> [Deck] {
        let snapshot = try await db.collection("decks")
            .whereField("ownerID", isEqualTo: userID)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Deck.self) }
    }
}
