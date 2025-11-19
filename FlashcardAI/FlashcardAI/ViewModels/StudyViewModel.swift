//
//  StudyViewModel.swift
//  FlashcardAI
//
//  Manages study session state and card navigation
//

import Foundation

class StudyViewModel: ObservableObject {
    @Published var currentIndex: Int = 0
    @Published var isShowingBack: Bool = false
    @Published var cards: [Card]

    private let originalCards: [Card]

    init(cards: [Card]) {
        self.originalCards = cards
        self.cards = cards
    }

    // MARK: - Computed Properties

    var currentCard: Card? {
        guard !cards.isEmpty, currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    var progress: Double {
        guard !cards.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(cards.count)
    }

    var progressText: String {
        guard !cards.isEmpty else { return "0 of 0" }
        return "\(currentIndex + 1) of \(cards.count)"
    }

    var canGoPrevious: Bool {
        return currentIndex > 0
    }

    var canGoNext: Bool {
        return currentIndex < cards.count - 1
    }

    var isLastCard: Bool {
        return currentIndex == cards.count - 1
    }

    // MARK: - Actions

    func flipCard() {
        isShowingBack.toggle()
    }

    func nextCard() {
        guard canGoNext else { return }
        currentIndex += 1
        isShowingBack = false
    }

    func previousCard() {
        guard canGoPrevious else { return }
        currentIndex -= 1
        isShowingBack = false
    }

    func shuffle() {
        cards = originalCards.shuffled()
        currentIndex = 0
        isShowingBack = false
    }

    func reset() {
        currentIndex = 0
        isShowingBack = false
    }
}
