//
//  OpenRouterManager.swift
//  FlashcardAI
//
//  Created by River Bumpas on 10/29/25.
//

import Foundation

// MARK: - Models
// Codable to translate between JSON and Swift types
struct OpenRouterRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double?
    let maxTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct Message: Codable {
    let role: String  // "user", "assistant" or "system"
    let content: String
}

struct OpenRouterResponse: Codable {
    let id: String
    let choices: [Choice]
    let usage: Usage?
}

struct Choice: Codable {
    let message: Message
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
        
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - API Service
class OpenRouterService {
    private let apiKey: String
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    
    init(apiKey: String) {
            self.apiKey = apiKey
        }
    
    func sendMessage(
        prompt: String,
        model: String = "meta-llama/llama-3.3-70b-instruct:free",
        conversationHistory: [Message] = []
    ) async throws -> String {
        // Build messages array
        var messages = conversationHistory
        messages.append(Message(role: "user", content: prompt))
        
        let request = OpenRouterRequest(
            model: model,
            messages: messages,
            temperature: 0.7,
            maxTokens: 1000
        )
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "OpenRouterService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
        }
        
        let openRouterResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)

        guard let firstChoice = openRouterResponse.choices.first else {
            throw NSError(
                domain: "OpenRouterService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No response from API"]
            )
        }

        return firstChoice.message.content
        
    }
    
}


