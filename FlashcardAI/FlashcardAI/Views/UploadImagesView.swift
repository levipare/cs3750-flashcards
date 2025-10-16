//
//  UploadImagesView.swift
//  FlashcardAI
//
//  Created by River Bumpas on 10/15/25.
//
import SwiftUI

struct UploadImagesView: View {
    
    @State private var viewModel = ViewModel()
    @State private var selectedLibraryImage: UIImage?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Camera preview
                CameraView(image: $viewModel.currentFrame)
                    .frame(maxHeight: .infinity)
                
                // Bottom controls and image gallery
                VStack(spacing: 16) {
                    // Control buttons
                    HStack(spacing: 40) {
                        // Upload from library button
                        Button(action: {
                            viewModel.showImagePicker = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 30))
                                Text("Library")
                                    .font(.caption)
                            }
                        }
                        
                        // Capture photo button
                        Button(action: {
                            viewModel.capturePhoto()
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .frame(width: 70, height: 70)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 60, height: 60)
                            }
                        }
                        
                        // Image count indicator
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 40, height: 40)
                                Text("\(viewModel.capturedImages.count)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            Text("Images")
                                .font(.caption)
                        }
                    }
                    .padding(.vertical)
                    
                    // Thumbnail gallery
                    if !viewModel.capturedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(viewModel.capturedImages.enumerated()), id: \.offset) { index, image in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        
                                        // Delete button
                                        Button(action: {
                                            viewModel.removeImage(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color.black.opacity(0.6)))
                                        }
                                        .padding(4)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 100)
                    }
                }
                .background(.ultraThinMaterial)
            }
            
            // Success message overlay
            if viewModel.showSuccessMessage {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text("Image uploaded successfully!")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                    .padding(.top, 50)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: viewModel.showSuccessMessage)
            }
        }
        .foregroundColor(.white)
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(image: $selectedLibraryImage)
        }
        .onChange(of: selectedLibraryImage) { _, newImage in
            if let newImage = newImage {
                viewModel.addImageFromLibrary(newImage)
                selectedLibraryImage = nil
            }
        }
    }
}

//#Preview {
//    UploadImagesView()
//}
