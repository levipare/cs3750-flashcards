//
//  DecksViewModel.swift
//  FlashcardAI
//
//  Created by Levi Pare on 10/22/25.
//

import FirebaseFirestore
import Foundation

class DecksViewModel: ObservableObject {
    @Published var decks: [Deck] = []
    private let db = Firestore.firestore()
    var userID: String = ""

    /// Fetch all decks belonging to a specific user
    func fetchDecks(for ownerID: String) async {
        do {
            let snapshot = try await db.collection("decks")
                .whereField("ownerID", isEqualTo: ownerID)
                .getDocuments()

            try await MainActor.run {
                self.decks = try snapshot.documents.compactMap { doc in
                    try doc.data(as: Deck.self)
                }
            }
        } catch {
            print("Error fetching decks: \(error.localizedDescription)")
        }
    }

    /// Fetch decks for the current user
    func fetchDecks() async {
        await fetchDecks(for: userID)
    }

    /// Add a new deck
    func addDeck(title: String, ownerID: String, cardCount: Int) async {
        do {
            let deck = Deck(
                title: title,
                ownerID: ownerID,
                cardCount: cardCount
            )
            _ = try db.collection("decks").addDocument(from: deck)
            await fetchDecks(for: ownerID)
        } catch {
            print("Error adding deck: \(error.localizedDescription)")
        }
    }

    /// Add a new deck and return its ID
    func addDeck(_ deck: Deck) async throws -> String {
        let docRef = try db.collection("decks").addDocument(from: deck)
        return docRef.documentID
    }

    /// Delete a deck by ID
    func deleteDeck(deckID: String) async {
        do {
            try await db.collection("decks").document(deckID).delete()
            await MainActor.run {
                decks.removeAll { $0.id == deckID }
            }
        } catch {
            print("Error deleting deck: \(error.localizedDescription)")
        }
    }

    /// Update an existing deck
    func updateDeckTitle(deckID: String, title: String) async {
        do {
            try await db.collection("decks")
                .document(deckID)
                .updateData([
                    "title": title
                ])

            await MainActor.run {
                if let index = decks.firstIndex(where: { $0.id == deckID }) {
                    decks[index].title = title
                }
            }
        } catch {
            print("Error updating deck title: \(error.localizedDescription)")
        }
    }

    /// Update the card count for a deck
    func updateCardCount(deckID: String, cardCount: Int) async {
        do {
            try await db.collection("decks")
                .document(deckID)
                .updateData([
                    "cardCount": cardCount
                ])

            await MainActor.run {
                if let index = decks.firstIndex(where: { $0.id == deckID }) {
                    decks[index].cardCount = cardCount
                }
            }
        } catch {
            print("Error updating card count: \(error.localizedDescription)")
        }
    }
}
