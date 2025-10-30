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
    @State private var showConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.decks) { deck in
                    deckRow(deck: deck)
                }
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
                            "Deck From Images",
                            destination: UploadImagesView()
                        )
                        Button("Empty Deck") {
                            Task {
                                await viewModel.addDeck(
                                    title: "Untitled Deck",
                                    ownerID: Auth.auth().currentUser?.uid ?? "",
                                    cardCount: 0
                                )
                            }
                        }
                        Button("Enter Share Code", action: {})
                    } label: {
                        Label("New Deck", systemImage: "plus")
                            .labelStyle(.iconOnly)
                    }.menuOrder(.fixed)
                }
            }
            .overlay {
                if viewModel.decks.isEmpty {
                    VStack {
                        Image(systemName: "square.stack.3d.up.fill").font(
                            .system(size: 48)
                        ).foregroundStyle(.gray)
                        Text("No Decks").font(.title.bold()).foregroundStyle(
                            .gray
                        )
                    }
                }
            }
            .task {
                await viewModel.fetchDecks(
                    for: Auth.auth().currentUser?.uid ?? ""
                )
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
