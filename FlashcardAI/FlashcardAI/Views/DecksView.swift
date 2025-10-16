//
//  DecksView.swift
//  FlashcardAI
//
//  Created by Levi Pare on 10/16/25.
//

import SwiftUI

struct DecksView: View {
    // example data
    @State private var decks: [Deck] = [
        Deck(id: "0", title: "Chinese Vocabulary", ownerID: ""),
        Deck(id: "1", title: "Computer Science", ownerID: ""),
        Deck(id: "2", title: "US Presidents", ownerID: ""),
        Deck(id: "3", title: "Physics Equations", ownerID: ""),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack() {
                    ForEach(decks) { deck in
                        DeckEntry(deck: deck)
                    }
                }
                .padding()
            }
            .navigationTitle("My Decks")
        }
    }
}

struct DeckEntry: View {
    let deck: Deck

    var body: some View {
        NavigationLink(destination: DeckDetailView(deck: deck, cards: [])) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(deck.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("\(Int.random(in: 5...30)) cards")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

struct DeckDetailView: View {
    let deck: Deck
    let cards: [Card]

    var body: some View {
        List(cards) { card in
            Text(card.frontText)
        }
        .navigationTitle(deck.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
