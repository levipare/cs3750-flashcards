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
    private let deckID : String
    
    init(deckID: String) {
        self.deckID = deckID
    }

    /// Fetch all cards for a given deck
    func fetchCards() async {
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
    func addCard(front: String, back: String) async {
        do {
            let card = Card(front: front, back: back)
            _ = try db.collection("decks")
                .document(deckID)
                .collection("cards")
                .addDocument(from: card)
            
            await fetchCards()
        } catch {
            print("Error adding card: \(error.localizedDescription)")
        }
    }

    /// Delete a card by ID
    func deleteCard(cardID: String) async {
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
    func updateCard(cardID: String, front: String, back: String) async {
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
