//
//  DeckDetailView.swift
//  FlashcardAI
//
//  Created by Levi Pare on 10/29/25.
//]

import FirebaseFirestore
import SwiftUI

struct DeckDetailView: View {
    @ObservedObject var decksViewModel: DecksViewModel
    @StateObject private var viewModel = CardsViewModel()
    @State private var selectedCard: Card? = nil
    @State private var showingNewCardSheet = false
    @State private var newCardFront = ""
    @State private var newCardBack = ""
    @State private var editFrontText = ""
    @State private var editBackText = ""
    @State private var title: String

    let deck: Deck

    init(deck: Deck, decksViewModel: DecksViewModel) {
        self.deck = deck
        self._title = State(initialValue: deck.title)
        self._decksViewModel = ObservedObject(initialValue: decksViewModel)
    }

    var body: some View {
        List {
            ForEach(viewModel.cards) { card in
                Button {
                    selectedCard = card
                    editFrontText = card.front
                    editBackText = card.back
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.front)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(card.back)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }.onDelete { indexSet in
                Task {
                    for index in indexSet {
                        let card = viewModel.cards[index]
                        await viewModel.deleteCard(
                            cardID: card.id ?? "",
                            deckID: deck.id ?? ""
                        )
                    }
                }
            }
        }
        .task {
            await viewModel.fetchCards(deckID: deck.id ?? "")
        }
        .overlay {
            if viewModel.cards.isEmpty {
                VStack {
                    Image(systemName: "text.page.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.gray)
                    Text("No Cards")
                        .font(.title.bold())
                        .foregroundStyle(.gray)
                }
            }
        }
        .navigationTitle($title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: title) { _, newTitle in
            Task {
                await decksViewModel.updateDeckTitle(deckID: deck.id ?? "", title: newTitle)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                Button {
                    showingNewCardSheet = true
                    newCardFront = ""
                    newCardBack = ""
                } label: {
                    Image(systemName: "plus")
                }
                .labelStyle(.iconOnly)
            }
        }
        // Edit card sheet
        .sheet(item: $selectedCard) { card in
            NavigationStack {
                Form {
                    Section(header: Text("Front")) {
                        TextEditor(text: $editFrontText).frame(minHeight: 100)
                    }
                    Section(header: Text("Back")) {
                        TextEditor(text: $editBackText).frame(minHeight: 100)
                    }
                }
                .navigationTitle("Edit Card")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            selectedCard = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task {
                                await viewModel.updateCard(
                                    deckID: deck.id ?? "",
                                    cardID: card.id ?? "",
                                    front: editFrontText,
                                    back: editBackText
                                )
                                selectedCard = nil
                            }
                        }.disabled(
                            editFrontText.isEmpty || editBackText.isEmpty
                        )
                    }
                }
            }
        }
        // New card sheet
        .sheet(isPresented: $showingNewCardSheet) {
            NavigationStack {
                Form {
                    Section(header: Text("Front")) {
                        TextEditor(text: $newCardFront).frame(minHeight: 100)
                    }
                    Section(header: Text("Back")) {
                        TextEditor(text: $newCardBack).frame(minHeight: 100)
                    }
                }
                .navigationTitle("New Card")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingNewCardSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            Task {
                                await viewModel.addCard(
                                    deckID: deck.id ?? "",
                                    front: newCardFront,
                                    back: newCardBack
                                )
                                showingNewCardSheet = false
                            }
                        }
                        .disabled(newCardFront.isEmpty || newCardBack.isEmpty)
                    }
                }
            }
        }
    }
}
