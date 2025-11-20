//
//  ChatView.swift
//  FlashcardAI
//
//  Created by River Bumpas on 10/29/25.
//
// CREATED TO TEST LLM API CONNECTION, WILL BE DELETED
import SwiftUI

struct ChatView: View {
    @State private var userInput = ""
    @State private var response = ""
    @State private var isLoading = false
    @State private var conversationHistory: [Message] = []
    
    private let apiService = OpenRouterService(apiKey: Secrets.openRouterAPIKey)
    
    var body: some View {
        VStack {
            ScrollView {
                Text(response)
                    .padding()
            }
            
            HStack {
                TextField("Ask something...", text: $userInput)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isLoading)
                
                Button("Send") {
                    sendMessage()
                }
                .disabled(isLoading || userInput.isEmpty)
            }
            .padding()
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
    }
    
    private func sendMessage() {
        isLoading = true
        let prompt = userInput
        userInput = ""
        
        Task {
            do {
                let result = try await apiService.sendMessage(
                    prompt: prompt,
                    model: "meta-llama/llama-3.3-70b-instruct:free",
                    conversationHistory: conversationHistory
                )
                
                // Update conversation history
                conversationHistory.append(Message(role: "user", content: prompt))
                conversationHistory.append(Message(role: "assistant", content: result))
                
                response = result
            } catch {
                response = "Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}
