//
//  GeneratedCard.swift
//  FlashcardAI
//
//  Created by Surya Malik on 11/12/25.
//

import Foundation

/// Response wrapper containing array of generated cards
struct GeneratedCardResponse: Codable {
    let cards: [GeneratedCard]
}

/// Individual generated card from LLM
struct GeneratedCard: Codable, Identifiable {
    let id = UUID()
    let type: String
    let question: String
    let options: [String]?
    let correct_answer: String
    let explanation: String?
    let support: [String]?
    let tags: [String]?

    enum CodingKeys: String, CodingKey {
        case type, question, options, correct_answer, explanation, support, tags
    }

    // MARK: - Helper Methods

    /// Extract deck name from tags array
    /// Looks for "deck: ..." pattern
    var deckName: String? {
        guard let tags = tags else { return nil }

        for tag in tags {
            if tag.lowercased().hasPrefix("deck:") {
                let name = tag.dropFirst(5).trimmingCharacters(in: .whitespaces)
                return name.isEmpty ? nil : name
            }
        }
        return nil
    }

    /// Extract difficulty from tags array
    /// Looks for "difficulty: ..." pattern
    var difficulty: String? {
        guard let tags = tags else { return nil }

        for tag in tags {
            if tag.lowercased().hasPrefix("difficulty:") {
                let difficulty = tag.dropFirst(11).trimmingCharacters(in: .whitespaces)
                return difficulty.isEmpty ? nil : difficulty
            }
        }
        return nil
    }

    /// Get regular tags (excluding deck: and difficulty: tags)
    var regularTags: [String] {
        guard let tags = tags else { return [] }

        return tags.filter { tag in
            let lowercased = tag.lowercased()
            return !lowercased.hasPrefix("deck:") && !lowercased.hasPrefix("difficulty:")
        }
    }

    // MARK: - Conversion to Card

    /// Convert GeneratedCard to Card model (front/back format)
    func toCard() -> Card {
        let front = formatFront()
        let back = formatBack()

        return Card(front: front, back: back)
    }

    /// Format the front of the card
    private func formatFront() -> String {
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
    private func formatBack() -> String {
        var back = correct_answer

        // Add explanation if available
        if let explanation = explanation, !explanation.isEmpty {
            back += "\n\n\(explanation)"
        }

        return back
    }
}
