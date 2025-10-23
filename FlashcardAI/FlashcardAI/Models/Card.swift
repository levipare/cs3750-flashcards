//
//  Card.swift
//  FlashcardAI
//
//  Created by Levi Pare on 10/16/25.
//

import FirebaseFirestore

struct Card: Identifiable, Codable {
    @DocumentID var id: String?
    var front: String
    var back: String
}
