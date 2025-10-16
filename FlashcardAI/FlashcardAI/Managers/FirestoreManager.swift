//
//  FirestoreManager.swift
//  FlashcardAI
//
//  Created by Surya Malik on 10/15/25.
//

import FirebaseFirestore

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
    
    func fetchCards(for deckID: String) async throws -> [Card] {
        let snapshot = try await db.collection("decks/\(deckID)/cards").getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Card.self) }
    }
}
