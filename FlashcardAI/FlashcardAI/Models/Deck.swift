//
//  Deck.swift
//  FlashcardAI
//
//  Created by Levi Pare on 10/16/25.
//

import FirebaseFirestore

struct Deck: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var ownerID: String
    var shareCode: String?
}
