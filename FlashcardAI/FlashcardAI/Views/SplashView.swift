//
//  SplashView.swift
//  FlashcardAI
//
//  Created by River Bumpas on 10/15/25.
//
import SwiftUI

struct SplashView: View {

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 64, weight: .regular))
            Text("FlashcardAI")
                .font(.largeTitle).bold()
            Text("Turn images into study cards.")
                .foregroundStyle(.secondary)

            Spacer()
                .padding()
        }
    }
}
