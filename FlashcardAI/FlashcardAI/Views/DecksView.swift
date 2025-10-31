//
//  DecksView.swift
//  FlashcardAI
//
//  Created by Levi Pare on 10/16/25.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import VisionKit


struct DecksView: View {
    @StateObject private var viewModel = DecksViewModel()
    @State private var showConfirmation = false
    @State private var showShareCodeAlert = false
    @State private var shareCode = ""
    @State private var showNewDeckAlert = false
    @State private var newDeckTitle = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.decks) { deck in
                    deckRow(deck: deck)
                }
            }
            .task {
                await viewModel.fetchDecks(
                    for: Auth.auth().currentUser?.uid ?? ""
                )
            }
            .navigationTitle("Decks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape.fill")
                            .labelStyle(.iconOnly)
                    }
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    Menu {
                        NavigationLink(
                            "Generate Deck",
                            destination: UploadNotesView()
                        )
                        Button("Create Empty Deck") {
                            newDeckTitle = ""
                            showNewDeckAlert = true
                        }
                        Button("Enter Share Code") {
                            shareCode = ""
                            showShareCodeAlert = true
                        }
                    } label: {
                        Label("New Deck", systemImage: "plus")
                            .labelStyle(.iconOnly)
                    }.menuOrder(.fixed)
                }
            }
            .overlay {
                if viewModel.decks.isEmpty {
                    ContentUnavailableView("No Decks", systemImage: "square.stack.3d.up.fill", description: Text("Create a deck by using the '+' in the lower right."))
                }
            }
            .alert("Create deck.", isPresented: $showNewDeckAlert) {
                TextField("New Deck Title", text: $newDeckTitle)
                Button("Create", action: {
                    Task {
                        await viewModel.addDeck(
                            title: newDeckTitle,
                            ownerID: Auth.auth().currentUser?.uid ?? "",
                            cardCount: 0
                        )
                    }
                }).disabled(newDeckTitle.isEmpty)
                Button("Cancel", role: .cancel, action: {})
            }
            .alert("Enter a share code.", isPresented: $showShareCodeAlert) {
                TextField("Code", text: $shareCode)
                Button("Add", action: {})
                Button("Cancel", role: .cancel, action: {})
            }
        }
    }

    private func deckRow(deck: Deck) -> some View {
        NavigationLink(
            destination: DeckDetailView(
                deck: deck,
                decksViewModel: viewModel
            )
        ) {
            VStack(alignment: .leading) {
                Text(deck.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(deck.cardCount) cards")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .swipeActions {
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
            Button("Delete Deck", role: .destructive) {
                Task {
                    await viewModel.deleteDeck(deckID: deck.id ?? "")
                }
            }
        }
    }
}
