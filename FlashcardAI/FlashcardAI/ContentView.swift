//
//  ContentView.swift
//  FlashcardAI
//
//  Created by River Bumpas on 10/15/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    var body: some View {
        Text(Auth.auth().currentUser?.email ?? "No user signed in")
            .padding()
            .onAppear {
                if let user = Auth.auth().currentUser {
                    print("User: \(user.email ?? "none") | UID: \(user.uid)")
                } else {
                    print("No user signed in")
                }
            }
    }
}

#Preview {
    ContentView()
}
