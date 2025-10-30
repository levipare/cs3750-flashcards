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
    func fetchCards(deckID: String) async {
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
    func addCard(deckID: String, front: String, back: String) async {
        do {
            let card = Card(front: front, back: back)
            _ = try db.collection("decks")
                .document(deckID)
                .collection("cards")
                .addDocument(from: card)
            
            await fetchCards(deckID: deckID)
        } catch {
            print("Error adding card: \(error.localizedDescription)")
        }
    }

    /// Delete a card by ID
    func deleteCard(cardID: String, deckID: String) async {
        do {
            try await db.collection("decks")
                .document(deckID)
                .collection("cards")
                .document(cardID)
                .delete()
            cards.removeAll { $0.id == cardID }
        } catch {
            print("Error deleting card: \(error.localizedDescription)")
        }
    }
    
    /// Update an existing card's front and back
    func updateCard(deckID: String, cardID: String, front: String, back: String) async {
        do {
            try await db.collection("decks")
                .document(deckID)
                .collection("cards")
                .document(cardID)
                .updateData([
                    "front": front,
                    "back": back
                ])
            
            // Update locally
            if let index = cards.firstIndex(where: { $0.id == cardID }) {
                cards[index].front = front
                cards[index].back = back
            }
        } catch {
            print("Error updating card: \(error.localizedDescription)")
        }
    }
}
