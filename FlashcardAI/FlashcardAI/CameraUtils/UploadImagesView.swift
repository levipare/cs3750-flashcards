//
//  UploadImagesView.swift
//  FlashcardAI
//
//  Created by River Bumpas on 10/15/25.
//
import SwiftUI

struct UploadImagesView: View {
    
    @State private var viewModel = ViewModel()
    
    var body: some View {
        CameraView(image: $viewModel.currentFrame)
    }
}

#Preview {
    UploadImagesView()
}
