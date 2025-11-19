//
//  DecksViewModel.swift
//  FlashcardAI
//
//  Created by Levi Pare on 10/22/25.
//

import FirebaseFirestore
import Foundation

enum DeckImportError: LocalizedError {
    case invalidCode
    case notFound

    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "Share codes must contain at least one letter or number."
        case .notFound:
            return "No deck matches that share code. Check the code and try again."
        }
    }
}

enum DeckShareError: LocalizedError {
    case missingDeckID
    case deckNotFound

    var errorDescription: String? {
        switch self {
        case .missingDeckID:
            return "Unable to share this deck because it has not been saved yet."
        case .deckNotFound:
            return "We couldn't find that deck anymore. Refresh and try again."
        }
    }
}

class DecksViewModel: ObservableObject {
    @Published var decks: [Deck] = []
    private let db = Firestore.firestore()
    private let ownerID: String
    
    init(ownerID: String) {
        self.ownerID = ownerID
    }

    /// Fetch all decks belonging to a specific user
    func fetchDecks() async {
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

    /// Add a new deck
    func addDeck(title: String, cardCount: Int) async {
        do {
            let shareCode = try await generateShareCode()
            let deck = Deck(
                title: title,
                ownerID: ownerID,
                cardCount: cardCount,
                shareCode: shareCode
            )
            _ = try db.collection("decks").addDocument(from: deck)
            await fetchDecks()
        } catch {
            print("Error adding deck: \(error.localizedDescription)")
        }
    }

    /// Add a new deck and return its ID
    func addDeck(_ deck: Deck) async throws -> String {
        var deckToSave = deck
        if deckToSave.shareCode.isEmpty {
            deckToSave.shareCode = try await generateShareCode()
        } else {
            deckToSave.shareCode = normalizeShareCode(deckToSave.shareCode)
        }

        let docRef = try db.collection("decks").addDocument(from: deckToSave)
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

    /// Fetch the share code for a deck, loading from Firestore if it is not already cached.
    func fetchShareCode(for deckID: String?) async throws -> String {
        guard let deckID else {
            throw DeckShareError.missingDeckID
        }

        if let deck = decks.first(where: { $0.id == deckID }),
           !deck.shareCode.isEmpty {
            return deck.shareCode
        }

        let document = try await db.collection("decks").document(deckID).getDocument()
        guard document.exists else {
            throw DeckShareError.deckNotFound
        }

        let deck = try document.data(as: Deck.self)
        return deck.shareCode
    }

    /// Import a deck from a share code by copying it into the user's collection
    func importDeck(shareCode rawCode: String) async throws {
        let shareCode = normalizeShareCode(rawCode)
        guard !shareCode.isEmpty else {
            throw DeckImportError.notFound
        }

        let deckQuery = try await db.collection("decks")
            .whereField("shareCode", isEqualTo: shareCode)
            .limit(to: 1)
            .getDocuments()

        guard let sharedDeckDoc = deckQuery.documents.first else {
            throw DeckImportError.notFound
        }

        let sharedDeck = try sharedDeckDoc.data(as: Deck.self)
        let cardsSnapshot = try await db.collection("decks")
            .document(sharedDeckDoc.documentID)
            .collection("cards")
            .order(by: "index")
            .getDocuments()
        let cards = try cardsSnapshot.documents.compactMap { try $0.data(as: Card.self) }

        let newDeck = Deck(
            title: sharedDeck.title,
            ownerID: ownerID,
            cardCount: cards.count
        )
        let newDeckID = try await addDeck(newDeck)

        if !cards.isEmpty {
            let batch = db.batch()
            let newDeckRef = db.collection("decks").document(newDeckID)

            for card in cards {
                let cardRef = newDeckRef.collection("cards").document()
                let clonedCard = Card(
                    index: card.index,
                    front: card.front,
                    back: card.back
                )
                try batch.setData(from: clonedCard, forDocument: cardRef)
            }
            try await batch.commit()
        }

        await fetchDecks()
    }

    private func generateShareCode(length: Int = 6) async throws -> String {
        let characters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

        while true {
            let code = String((0..<length).compactMap { _ in characters.randomElement() })
            let snapshot = try await db.collection("decks")
                .whereField("shareCode", isEqualTo: code)
                .limit(to: 1)
                .getDocuments()
            if snapshot.documents.isEmpty {
                return code
            }
        }
    }

    private func normalizeShareCode(_ code: String) -> String {
        code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }
}
