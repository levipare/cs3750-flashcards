//
//  CardPreviewView.swift
//  FlashcardAI
//
//  Created by Surya Malik on 11/12/25.
//

import SwiftUI
import FirebaseAuth

struct CardPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var decksViewModel: DecksViewModel

    let generatedCards: [GeneratedCard]
    let onDeckSaved: () -> Void
    @State private var editableCards: [EditableCard] = []
    @State private var deckName: String = ""
    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Deck name section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Deck Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("Enter deck name", text: $deckName)
                        .textFieldStyle(.roundedBorder)
                }
                .padding()
                .background(Color(.systemGroupedBackground))

                // Card list
                List {
                    ForEach($editableCards) { $card in
                        VStack(alignment: .leading, spacing: 12) {
                            // Front
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Front")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                TextEditor(text: $card.front)
                                    .frame(minHeight: 60)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }

                            // Back
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Back")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                TextEditor(text: $card.back)
                                    .frame(minHeight: 80)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onDelete(perform: deleteCards)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Review Cards (\(editableCards.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Deck") {
                        Task {
                            await saveDeck()
                        }
                    }
                    .disabled(deckName.isEmpty || editableCards.isEmpty || isSaving)
                }
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Saving \(editableCards.count) cards...")
                                .font(.footnote)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .onAppear {
            setupEditableCards()
        }
        .alert("Save Failed", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
    }

    private func setupEditableCards() {
        // Convert generated cards to editable cards
        editableCards = generatedCards.map { genCard in
            EditableCard(
                id: UUID(),
                front: genCard.formatFront(),
                back: genCard.formatBack()
            )
        }

        // Set deck name from tags if available
        if deckName.isEmpty {
            if let firstCard = generatedCards.first,
               let extractedDeckName = firstCard.deckName {
                deckName = extractedDeckName
            }
        }
    }

    private func deleteCards(at offsets: IndexSet) {
        editableCards.remove(atOffsets: offsets)
    }

    private func saveDeck() async {
        guard !deckName.isEmpty, !editableCards.isEmpty else { return }

        await MainActor.run {
            isSaving = true
            saveError = nil
        }

        do {
            // Create the deck
            let deck = Deck(
                title: deckName,
                ownerID: Auth.auth().currentUser?.uid ?? "",
                cardCount: editableCards.count
            )

            let deckID = try await decksViewModel.addDeck(deck)

            // Save all cards to the deck
            let cardsViewModel = CardsViewModel(deckID: deckID)

            for editableCard in editableCards {
                await cardsViewModel.addCard(front: editableCard.front, back: editableCard.back)
            }

            // Refresh decks list
            await decksViewModel.fetchDecks()

            await MainActor.run {
                isSaving = false
                onDeckSaved()
                dismiss()
            }
        } catch {
            await MainActor.run {
                isSaving = false
                saveError = error.localizedDescription
            }
        }
    }
}

/// Editable version of a card for the preview
struct EditableCard: Identifiable {
    let id: UUID
    var front: String
    var back: String
}

// MARK: - Helper Extension

extension GeneratedCard {
    /// Format the front of the card
    fileprivate func formatFront() -> String {
        var front = question

        // Add options if this is a multiple choice question
        if let options = options, !options.isEmpty {
            front += "\n\n"
            for (index, option) in options.enumerated() {
                let letter = String(UnicodeScalar(65 + index)!) // A, B, C, D...
                front += "\n\(letter). \(option)"
            }
        }

        return front
    }

    /// Format the back of the card
    fileprivate func formatBack() -> String {
        var back = correct_answer

        // Add explanation if available
        if let explanation = explanation, !explanation.isEmpty {
            back += "\n\n\(explanation)"
        }

        return back
    }
}
