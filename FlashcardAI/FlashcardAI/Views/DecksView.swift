//
//  DecksView.swift
//  FlashcardAI
//
//  Created by Levi Pare on 10/16/25.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct DecksView: View {
    @StateObject private var viewModel = DecksViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.decks) { deck in
                DeckEntry(deck: deck)
            }
            .navigationTitle("My Decks")
        }.task {
            await viewModel.fetchDecks(for: Auth.auth().currentUser?.uid ?? "")
        }
    }
}

struct DeckEntry: View {
    let deck: Deck

    var body: some View {
        NavigationLink(destination: DeckDetailView(deck: deck)) {
            VStack(alignment: .leading) {
                Text(deck.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("\(deck.cardCount) cards")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct DeckDetailView: View {
    @StateObject private var viewModel = CardsViewModel()
    let deck: Deck

    var body: some View {
        List(viewModel.cards) { card in
            VStack(alignment: .leading, spacing: 8) {
                Text(card.front)
                    .font(.headline)
                Text(card.back)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .navigationTitle(deck.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .task {
            await viewModel.fetchCards(for: deck.id ?? "")
        }
    }
}
