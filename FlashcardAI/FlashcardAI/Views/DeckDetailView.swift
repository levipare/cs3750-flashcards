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
    @StateObject private var viewModel : CardsViewModel
    @State private var selectedCard: Card? = nil
    @State private var showingNewCardSheet = false
    @State private var newCardFront = ""
    @State private var newCardBack = ""
    @State private var editFrontText = ""
    @State private var editBackText = ""
    @State private var title: String
    @State private var showConfirmation = false

    let deck: Deck

    init(deck: Deck, decksViewModel: DecksViewModel) {
        self.deck = deck
        self._title = State(initialValue: deck.title)
        self._viewModel = StateObject(wrappedValue: CardsViewModel(deckID: deck.id ?? ""))
        self._decksViewModel = ObservedObject(initialValue: decksViewModel)
    }

    var body: some View {
        List {
            ForEach(viewModel.cards) { card in
                cardRow(card: card)
            }
        }
        .task {
            await viewModel.fetchCards()
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
                } label: {
                    Image(systemName: "plus")
                }
                .labelStyle(.iconOnly)
            }
        }
        .sheet(item: $selectedCard) { card in
            editCardSheet(card: card)
        }
        .sheet(isPresented: $showingNewCardSheet) {
            newCardSheet()
        }
    }
    
    private func editCardSheet(card: Card) -> some View {
        NavigationStack {
            Form {
                Section(header: Text("Front")) {
                    TextEditor(text: $editFrontText).frame(minHeight: 100)
                }.onAppear {
                    editFrontText = card.front
                }
                Section(header: Text("Back")) {
                    TextEditor(text: $editBackText).frame(minHeight: 100)
                }.onAppear {
                    editBackText = card.back
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
    
    private func newCardSheet() -> some View {
        NavigationStack {
            Form {
                Section(header: Text("Front")) {
                    TextEditor(text: $newCardFront).frame(minHeight: 100).onAppear {
                        newCardFront = ""
                    }
                }
                Section(header: Text("Back")) {
                    TextEditor(text: $newCardBack).frame(minHeight: 100).onAppear {
                        newCardBack = ""
                    }
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
    
    private func cardRow(card: Card) -> some View {
        Button {
            selectedCard = card
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
        }.swipeActions {
            Button {
                showConfirmation = true
            } label: {
                Image(systemName: "trash")
            }.tint(.red)
        }
        .confirmationDialog(
            "Are you sure?",
            isPresented: $showConfirmation,
            titleVisibility: .visible,
        ) {
            Button("Delete Card", role: .destructive) {
                Task {
                    await viewModel.deleteCard(cardID: card.id ?? "")
                }
            }
        }
    }
}
