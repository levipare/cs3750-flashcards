//
//  Prompt.swift
//  FlashcardAI
//
//  Created by River Bumpas on 11/11/25.
//

import FirebaseFirestore

struct Prompt: Identifiable, Codable {
    @DocumentID var id: String?
    var text: String
}
