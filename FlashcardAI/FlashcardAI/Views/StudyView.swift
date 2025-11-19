//
//  StudyView.swift
//  FlashcardAI
//
//  Study interface with card flipping and navigation
//

import SwiftUI

struct StudyView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: StudyViewModel

    init(cards: [Card], shuffled: Bool = false) {
        _viewModel = StateObject(wrappedValue: StudyViewModel(cards: cards, shuffled: shuffled))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar with progress
            topToolbar

            // Main card display area
            ZStack {
                if let card = viewModel.currentCard {
                    cardView(card: card)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 40)
                } else {
                    emptyStateView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom navigation bar
            bottomNavigationBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Exit") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.toggleShuffle()
                } label: {
                    Image(systemName: viewModel.isShuffled ? "shuffle" : "arrow.up.arrow.down")
                }
            }
        }
    }

    // MARK: - Top Toolbar

    private var topToolbar: some View {
        VStack(spacing: 8) {
            Text(viewModel.progressText)
                .font(.headline)
                .foregroundColor(.secondary)

            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Card View

    private func cardView(card: Card) -> some View {
        ZStack {
            // Back of card
            CardSide(
                text: card.back,
                isBack: true
            )
            .opacity(viewModel.isShowingBack ? 1 : 0)
            .rotation3DEffect(
                .degrees(viewModel.isShowingBack ? 0 : -180),
                axis: (x: 0, y: 1, z: 0)
            )

            // Front of card
            CardSide(
                text: card.front,
                isBack: false
            )
            .opacity(viewModel.isShowingBack ? 0 : 1)
            .rotation3DEffect(
                .degrees(viewModel.isShowingBack ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.6)) {
                viewModel.flipCard()
            }
        }
    }

    // MARK: - Bottom Navigation

    private var bottomNavigationBar: some View {
        HStack(spacing: 20) {
            // Previous button
            Button {
                withAnimation {
                    viewModel.previousCard()
                }
            } label: {
                Label("Previous", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.canGoPrevious)

            // Next/Finish button
            if viewModel.isLastCard {
                Button {
                    dismiss()
                } label: {
                    Label("Finish", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    withAnimation {
                        viewModel.nextCard()
                    }
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .labelStyle(.titleAndIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canGoNext)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.on.rectangle.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No cards to study")
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Card Side Component

struct CardSide: View {
    let text: String
    let isBack: Bool

    var body: some View {
        VStack {
            if !isBack {
                Text("Tap to reveal answer")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }

            ScrollView {
                Text(text)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(isBack ? Color.blue.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}
