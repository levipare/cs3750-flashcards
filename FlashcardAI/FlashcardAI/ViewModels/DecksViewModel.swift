//
//  DecksViewModel.swift
//  FlashcardAI
//
//  Created by Levi Pare on 10/22/25.
//

import Foundation
import FirebaseFirestore

@MainActor
class DecksViewModel: ObservableObject {
    @Published var decks: [Deck] = []
    private let db = Firestore.firestore()

    /// Fetch all decks belonging to a specific user
    func fetchDecks(for ownerID: String) async {
        do {
            let snapshot = try await db.collection("decks")
                .whereField("ownerID", isEqualTo: ownerID)
                .getDocuments()
            
            self.decks = try snapshot.documents.compactMap { doc in
                try doc.data(as: Deck.self)
            }
        } catch {
            print("Error fetching decks: \(error.localizedDescription)")
        }
    }

    /// Add a new deck
    func addDeck(title: String, ownerID: String, cardCount: Int) async {
        do {
            let deck = Deck(title: title, ownerID: ownerID, cardCount: cardCount)
            _ = try db.collection("decks").addDocument(from: deck)
            await fetchDecks(for: ownerID)
        } catch {
            print("Error adding deck: \(error.localizedDescription)")
        }
    }

    /// Delete a deck by ID
    func deleteDeck(_ deck: Deck) async {
        guard let id = deck.id else { return }
        do {
            try await db.collection("decks").document(id).delete()
            decks.removeAll { $0.id == id }
        } catch {
            print("Error deleting deck: \(error.localizedDescription)")
        }
    }
}
