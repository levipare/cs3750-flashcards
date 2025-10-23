//
//  CardsViewModel.swift
//  FlashcardAI
//
//  Created by Levi Pare on 10/22/25.
//

import Foundation
import FirebaseFirestore

@MainActor
class CardsViewModel: ObservableObject {
    @Published var cards: [Card] = []
    private let db = Firestore.firestore()

    /// Fetch all cards for a given deck
    func fetchCards(for deckID: String) async {
        do {
            let snapshot = try await db.collection("decks")
                .document(deckID)
                .collection("cards")
                .getDocuments()
            
            self.cards = try snapshot.documents.compactMap { doc in
                try doc.data(as: Card.self)
            }
        } catch {
            print("Error fetching cards: \(error.localizedDescription)")
        }
    }

    /// Add a new card to a deck
    func addCard(to deckID: String, front: String, back: String) async {
        do {
            let card = Card(front: front, back: back)
            _ = try db.collection("decks")
                .document(deckID)
                .collection("cards")
                .addDocument(from: card)
            
            await fetchCards(for: deckID)
        } catch {
            print("Error adding card: \(error.localizedDescription)")
        }
    }

    /// Delete a card by ID
    func deleteCard(_ card: Card, from deckID: String) async {
        guard let id = card.id else { return }
        do {
            try await db.collection("decks")
                .document(deckID)
                .collection("cards")
                .document(id)
                .delete()
            cards.removeAll { $0.id == id }
        } catch {
            print("Error deleting card: \(error.localizedDescription)")
        }
    }
}
